#!/usr/bin/env ruby
#
# usage:
#  ./un-gqap-ify.pl < ~/workspace/writings/to_become_forever.md > /tmp/to_become_forever.md
#
# "joins" lines in same paragraph to one long line.
# removes empty lines (usually between paragraphs)
puts ARGF.read.gsub(/([^\n])\n([^\n)])/, '\1 \2').gsub(/\n\n/, "\n")
