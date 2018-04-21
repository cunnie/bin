#!/usr/bin/env ruby
#
# Input: a file of two columns, numbers: seconds and metric
# Output: a file of two numbers, collapsed hourly (3600 seconds). E.g.
#
#     0 6
#  3599 4
#  3600 7
# 10800 8
#
# Would become
#
#     0 5
#  3600 7
# 10800 8
#

limit=3600
metrics=[]
ARGF.each do |line|
  # print ARGF.filename, ":", line
  seconds, metric = line.split.map { |i| i.to_f }
  if seconds > limit
    print "#{limit - 3600}\t#{metrics.inject{ |sum, el| sum + el }.to_f / metrics.size}\n"
    metrics=[metric]
    limit += 3600
  else
    metrics << metric
  end
end
print "#{limit - 3600}\t#{metrics.inject{ |sum, el| sum + el }.to_f / metrics.size}\n"
