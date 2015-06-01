#!/usr/bin/env ruby

# converts my vim-based file to markdown
# and uses proper punctuation

pre_processed = ARGF.read

strip_crs = pre_processed.gsub(/([^\n])\n([^\n)])/, '\1 \2')

replace_quotes = []

strip_crs.split('\n').each do |line|
  while line =~ /"/
    line.sub!(/"/,'&ldquo;')
    line.sub!(/"/,'&rdquo;')
  end
  # apostrophes
  line.gsub!(/'/,'&rsquo;')
  replace_quotes << line
end

replace_quotes.each do |line|
  puts line
end


