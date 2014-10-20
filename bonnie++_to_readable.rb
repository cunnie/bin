#!/usr/bin/env ruby
#
# bonnie++_to_readable.rb < /tmp/bonnie.txt
#
STDIN.read.split("\n").each do |line|
  csv = line.split(/,/)
  if csv.size == 48
    #puts line
    description = csv[2]
    seq_write = csv[9].to_i / 1000
    seq_read = csv[15].to_i / 1000
    iops = csv[17]
    puts "#{description} #{seq_write} MB/s #{seq_read} MB/s #{iops} IOPS"
  end
end
