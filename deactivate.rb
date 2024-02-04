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
require 'json'

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

  def to_hash
    {
      firstName: @first_name,
      lastName: @last_name,
      partition: @partition,
      enabled: @enabled,
      activeDate: @active_date,
      expireDate: @expireDate,
      pin: @pin,
      duressPin: @duress_pin,
    }
  end
end

def to_snake_case(string)
  # Remove spaces and replace them with underscores
  string.gsub(' ', '_').downcase
end

raise 'Usage: deactivate.rb people.json deactivation_emails.txt' unless ARGV.length == 2

people_hash = JSON.parse(File.read(ARGV[0]))
people = people_hash.map do |person|
  Person.new(person)
end

File.foreach(ARGV[1]) do |line|
  deactivation_email = line.chomp
  user = people.select { |person| person.email == deactivation_email }.first
  unless user.email.nil?
    p user
    p user.to_hash
  end
end
