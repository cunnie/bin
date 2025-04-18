#!/usr/bin/env ruby

# typical use:
# dig @nono.io axfr nono.io. | a_to_ptr.rb | sudo tee /usr/local/etc/namedb/primary/9.10.in-addr.arpa
#
# Typical axfr output:
#
# www.nono.io.		300	IN	A	78.46.204.247
# www.nono.io.		300	IN	AAAA	2a01:4f8:c17:b8f::2

puts <<~AXFR
  $TTL 3h
  @ SOA mordor.nono.io. yoyo.nono.io. #{Time.now.to_i} 1d 12h 1w 3h
          ; Serial, Refresh, Retry, Expire, Neg. cache TTL

          NS      atom.nono.io.
AXFR

octet_to_record = {}
$stdin.read.split("\n").each do |line|
  next unless line.match?(/\tA\t/)

  fields = line.split(' ')
  # p fields
  fields[0].gsub!(/^\*\./,'') # '*' (wildcards) cause `named` to fail to load zone
  if fields[4].match?(/^10\.9\./)
    third_octet = fields[4].split('.')[2].to_i
    fourth_octet = fields[4].split('.')[3].to_i
    octet = third_octet * 256 + fourth_octet
    octet_to_record[octet] = "#{fourth_octet}.#{third_octet}\tPTR\t#{fields[0]}"
  end
end

octet_to_record.keys.sort.each do |octet|
  puts octet_to_record[octet]
end
