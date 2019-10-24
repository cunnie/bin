#!/usr/bin/env ruby
#
# bonnie++_to_readable.rb < /tmp/bonnie.txt
#
STDIN.read.split("\n").each do |line|
  if line.match? /^export/
    puts line
  end
  if line.include? "--issue"
    line.split.each do |word|
      if word =~ /^dns_/
        puts word
      end
    end
  end
end
