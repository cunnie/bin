#!/usr/bin/env ruby
# frozen_string_literal: true

# Usage:
#
#  ./deactivate.rb people.json deactivation_emails.txt
#
# where:
#
# - "people.json" is a list of ALL the people, ALL the fields downloaded
# from pdk.io in JSON format:
# https://pdk.io/appliances/1071P6X/reports/people/saved-reports
#
# - "emails.txt" is the email addr of the person to deactivate, one email
# per line, e.g.
#
#  yoyo@nono.io
#
# - needs two environment variables
#   PDK_CLIENT_ID=
#   PDK_CLIENT_SECRET=
#
require 'json'
require 'httparty'
require 'base64'

class Person
  attr_accessor :id, :first_name, :last_name, :email, :photo_url, :partition,
                :enabled, :active_date, :expire_date, :pin,
                :duress_pin, :custom_attributes,
                :metadata, :groups, :credentials

  def initialize(person)
    person.keys.each do |key|
      instance_variable_set("@#{to_snake_case(key)}", person[key])
    end
  end

  # Contains only the _required_ components of the PUT request
  def to_h
    {
      firstName: @first_name,
      lastName: @last_name,
      partition: @partition,
      enabled: @enabled,
      activeDate: @active_date,
      expireDate: @expire_date,
      pin: @pin,
      duressPin: @duress_pin
    }
  end

  # e.g. '02/03/2024 11:11:14'
  def expire!
    @expire_date ||= Time.now.strftime("%m/%d/%Y %H:%M:%S")
  end

  def to_json(*_args)
    JSON.generate(to_h)
  end
end

def to_snake_case(string)
  # Remove spaces and replace them with underscores
  string.gsub(' ', '_').downcase
end

raise 'Usage: deactivate.rb people.json deactivation_emails.txt' unless ARGV.length == 2
raise 'Must `export PDK_CLIENT_ID=<your PDK client id>`' if ENV['PDK_CLIENT_ID'].nil?
raise 'Must `export PDK_CLIENT_SECRET=<your PDK client secret>`' if ENV['PDK_CLIENT_SECRET'].nil?

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

puts response.body, response.code, response.message, response.headers.inspect

people_hash = JSON.parse(File.read(ARGV[0]))
people = people_hash.map do |person|
  Person.new(person)
end

File.foreach(ARGV[1]) do |line|
  deactivation_email = line.chomp
  user = people.select { |person| person.email == deactivation_email }.first
  unless user.email.nil?
    user.expire!
    p user
    p "Expiring #{user.first_name} #{user.last_name} email: #{user.email} id: #{user.id}"
    puts user.to_json
  end
end
