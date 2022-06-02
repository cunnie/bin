#!/usr/bin/env ruby
#
# usage: grep "SLEEP " ~/tmp/asgs_test.txt | grep -v echo | sort -n -k 2 | awk 'BEGIN { OLD=-1 } { print $2,$4,$6 }' | asg_results.rb
#
# reads from STDIN where the first number is seconds, 2nd, successes, 3rd, failurs
#
# 75 5 0
#
# output
#
# 0 *****
#

seconds=0
successes=0
failures=0
b=[]

puts "|Delay (seconds)|# of tests|Success Rate (%)|Success Rate Histogram |"
puts "|--:|--:|--:|:--|"

STDIN.read.split("\n").each do |a|
  b = a.split
  if seconds / 5 != b[0].to_i / 5
    puts "| #{seconds} | #{successes + failures} | #{successes*100/(successes+failures)} | #{'*'*(successes*25/(successes+failures))} |"
    seconds=b[0].to_i
    successes=b[1].to_i
    failures=b[2].to_i
  else
    successes += b[1].to_i
    failures += b[2].to_i
  end
end
puts "| #{seconds} | #{successes + failures} | #{successes*100/(successes+failures)} | #{'*'*(successes*25/(successes+failures))} |"
