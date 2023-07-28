#!/usr/bin/env ruby
#
# Converts subtitles/captions formatted for 25-frame
# PAL to 24-frame NTSC.
#
# Useful for Hercule Poirot DVDs
#
# pal_speedup_srt.rb < original.srt > fixed.srt
#
# Typical transform:
#
# "00:50:59,792 --> 00:51:03,700" → "00:48:57,400 --> 00:49:01,152"
#
# https://en.wikipedia.org/wiki/576i#PAL_speed-up
# https://en.wikipedia.org/wiki/SubRip
# https://en.wikipedia.org/wiki/Windows-1252

def srt_time_format(milliseconds)
  hours = (milliseconds / (1000 * 3600)).to_i
  milliseconds = milliseconds % (1000 * 3600)
  minutes = milliseconds / (1000 * 60)
  milliseconds = milliseconds % (1000 * 60)
  seconds = milliseconds / 1000
  milliseconds = milliseconds % 1000
  sprintf('%02d:%02d:%02d,%3d',hours,minutes,seconds,milliseconds)
end

def twenty_four_twenty_fifths(srt_time)
  hms, milliseconds = srt_time.split(',')
  hours, minutes, seconds = hms.split(':')
  total_milliseconds =
    1000 * 3600 * hours.to_i +
    1000 * 60 * minutes.to_i +
    1000 * seconds.to_i +
    milliseconds.to_i
  srt_time_format(total_milliseconds * 24 / 25)
end

# Check if everyting is working
unless twenty_four_twenty_fifths('25:25:25,250') == '24:24:24,240'
  p "Uh oh: #{twenty_four_twenty_fifths('25:25:25,250')} != 24:24:24,240"
  raise 'The calculation is wrong! Aborting...'
end

$stdin.read.force_encoding('Windows-1252').split("\n").each do |line|
  line.gsub!(/\r/, '') # get rid of DOS-terminated \r\n 0xd 0xa CR LF
  line.encode!('UTF-8', 'Windows-1252')
  if line.match?(/^\d\d:\d\d:\d\d,\d\d\d --> \d\d:\d\d:\d\d,\d\d\d$/)
    start_time, end_time = line.split(' --> ')
    puts "#{twenty_four_twenty_fifths(start_time)} --> #{twenty_four_twenty_fifths(end_time)}"
  else
    puts line
    raise 'Mis-parsed time' if line.match?(/ --> /)
  end
end
