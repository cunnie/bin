#!/usr/bin/env ruby
#
# grep Duration xenial-06.txt | awk 'NR%4 == 1 || NR%4 == 2 {print $4}' | hms_to_rb.rb
#
# Converts times in HH:MM:SS to seconds, e.g. "01:23:45" → "5025"
#
STDIN.read.split("\n").each do |line|
  hours, minutes, seconds = line.split(/:/)
  total_seconds = 3600 * hours.to_i + 60 * minutes.to_i + seconds.to_i
  p total_seconds
end
