#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage:
#
#  ./pdk_create.rb people.csv
#
# where:
#
# - "people.csv" is a comma-separated values file containing first name
# last name, and email of people to be added to PDK.
#
#     Brian,Cunnie,brian.cunnie@serc.com
#
# - needs two environment variables
#   PDK_CLIENT_ID=
#   PDK_CLIENT_SECRET=
#
require 'json'
require 'httparty'
require 'base64'
require 'csv'

class Person
  attr_accessor :id, :first_name, :last_name, :email, :photo_url, :partition,
                :enabled, :active_date, :expire_date, :pin,
                :duress_pin, :custom_attributes,
                :metadata, :groups, :credentials

  def initialize(person)
    person.each_key do |key|
      instance_variable_set("@#{to_snake_case(key)}", person[key])
    end
  end

  def partition_id
    raise 'Non-default partition Id' if @partition != 'Default'

    0 # Default partition for us is "0"
  end

  # Contains only the _required_ components of the PUT request
  def to_h
    {
      firstName: @first_name,
      lastName: @last_name,
      partition: partition_id,
      enabled: @enabled,
      activeDate: @active_date,
      expireDate: @expire_date,
      pin: @pin,
      duressPin: @duress_pin,
      email: @email
    }
  end

  # e.g. '02/03/2024 11:11:14'
  def disable!
    # @expire_date ||= Time.now.strftime("%m/%d/%Y %H:%M:%S")
    @enabled = false
  end

  def to_json(*_args)
    JSON.generate(to_h)
  end

  def to_s
    "#{first_name}\t#{last_name}\t#{email}"
  end
end

def to_snake_case(string)
  # Remove spaces and replace them with underscores
  string.gsub(' ', '_').downcase
end

class PDK
  def initialize
    @panel_id = '1071P6X'
    @id_token = id_token
    @panel_token = panel_token
  end

  def id_token
    client_id_secret = "#{ENV['PDK_CLIENT_ID']}:#{ENV['PDK_CLIENT_SECRET']}"
    encoded_client_id_secret = Base64.strict_encode64(client_id_secret)
    response = HTTParty.post(
      'https://accounts.pdk.io/oauth2/token',
      headers: {
        'Authorization' => "Basic #{encoded_client_id_secret}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials'
    )
    if response.code != 200
      puts response.body, response.code, response.message, response.headers.inspect
      raise "couldn't authenticate id_token!"
    end
    JSON.parse(response.body)['id_token']
  end

  def panel_token
    response = HTTParty.post(
      "https://accounts.pdk.io/api/panels/#{@panel_id}/token",
      headers: {
        'Authorization' => "Bearer #{@id_token}"
      },
      body: 'grant_type=client_credentials'
    )
    if response.code != 200
      puts response.body, response.code, response.message, response.headers.inspect
      raise "couldn't authenticate panel_token!"
    end
    JSON.parse(response.body)['token']
  end

  def lock_out(user)
    panel_id = '1071P6X'
    response = HTTParty.put(
      "https://panel-#{panel_id}.pdk.io/api/persons/#{user.id}",
      headers: {
        'Authorization' => "Bearer #{@panel_token}",
        'Content-Type' => 'application/json'
      },
      body: user.to_json
    )
    if response.code == 204
      "✅ Locked-out #{user.first_name} #{user.last_name} email: #{user.email} id: #{user.id}"
    else
      puts response.body, response.code, response.message, response.headers.inspect
      "⛔️ Failed to lock-out #{user.first_name} #{user.last_name} email: #{user.email} id: #{user.id}"
    end
  end

  def create_person(person)
    response = HTTParty.post(
      "https://panel-#{@panel_id}.pdk.io/api/persons",
      headers: {
        'Authorization' => "Bearer #{@panel_token}",
        'Content-Type' => 'application/json'
      },
      body: person.to_json
    )
    if response.code != 200
      puts response.body, response.code, response.message, response.headers.inspect
      raise "⛔️ Failed to create #{person.first_name} #{person.last_name} email: #{person.email} id: #{person.id}"
    end
    return JSON.parse(response.body)['id'] # the numeric id of the created user
  end
end

raise 'Usage: pdk_create.rb people.csv' unless ARGV.length == 1
raise 'Must `export PDK_CLIENT_ID=<your PDK client id>`' if ENV['PDK_CLIENT_ID'].nil?
raise 'Must `export PDK_CLIENT_SECRET=<your PDK client secret>`' if ENV['PDK_CLIENT_SECRET'].nil?

people = []
pdk = PDK.new

CSV.foreach(ARGV[0]) do |row|
  first_name = row[0]
  last_name = row[1]
  email = row[2]
  person = Person.new(
    'first_name' => first_name,
    'last_name' => last_name,
    'email' => email,
    'partition' => 'Default',
    'enabled' => true,
    'active_date' => '2024-04-07T00:00:00',
    'expire_date' => '2024-04-17T00:00:00'
  )
  puts person.to_json
  people << person
  puts "Should I add #{person.first_name} #{person.last_name} #{person.email}?"
  response = $stdin.gets.chomp
  if response.downcase.start_with?('y')
    person.id = pdk.create_person(person)
    puts "✅ Created #{person.first_name} #{person.last_name} email: #{person.email} id: #{person.id}"
  else
    puts "⚠️  Skipping #{person.first_name} #{person.last_name} #{person.email}"
  end
end

puts people.sort_by(&:last_name)
exit

File.foreach(ARGV[1]) do |line|
  deactivation_email = line.chomp
  users = people.select { |person| person.email == deactivation_email }
  if users.length < 1
    puts "⛔️ email '#{deactivation_email}' doesn't have any corresponding users!"
    next
  end
  if users.length > 1
    puts "⛔️ email '#{deactivation_email}' has several users: " +
         users.map { |user| "#{user.first_name} #{user.last_name}" }.join(', ')
    next
  end
  user = users.first # by now we only have one user
  puts "Should I create #{user.first_name} #{user.last_name} #{user.email}?"
  puts `grep -i "#{user.last_name}" *.csv | sed 's/^/  /'`
  response = $stdin.gets.chomp
  if response.downcase.start_with?('y')
    user.disable!
    puts lock_out(user, token)
  else
    puts "⚠️  Skipping #{user.first_name} #{user.last_name} #{user.email}"
  end
end
