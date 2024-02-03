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

raise 'Usage: deactivate.rb people.json deactivation_emails.txt' unless ARGV.length == 2

people = JSON.parse(File.read(ARGV[0]))

File.foreach(ARGV[1]) do |line|
  deactivation_email = line.chomp
  user = people.select { |person| person['Email'] == deactivation_email }
  p user
end
