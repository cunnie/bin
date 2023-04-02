#!/usr/bin/env ruby

# typical use:
# dig @nono.io axfr nono.io. | aaaa_to_ptr.rb > /usr/local/etc/namedb/master/0.0.1.0.6.4.6.0.1.0.6.2.IP6.arpa
#
# Typical axfr output:
#
# www.nono.io.		300	IN	A	78.46.204.247
# www.nono.io.		300	IN	AAAA	2a01:4f8:c17:b8f::2

require 'ipaddr'

puts <<~AXFR
  $TTL 3h
  @ SOA atom.nono.io. yoyo.nono.io. #{Time.now.to_i} 1d 12h 1w 3h
          ; Serial, Refresh, Retry, Expire, Neg. cache TTL

          NS      atom.nono.io.
AXFR

ptr_to_record = {}
$stdin.read.split("\n").each do |line|
  next unless line.match?(/\tAAAA\t/)

  fields = line.split(' ')
  # p fields
  fields[0].gsub!(/^\*\./,'') # '*' (wildcards) cause `named` to fail to load zone
  if fields[4].match?(/^2601:646:100:/)
    ipv6_ptr = IPAddr.new(fields[4]).ip6_arpa
    ptr_to_record[ipv6_ptr] = "#{ipv6_ptr}.\tPTR\t#{fields[0]}"
  end
end

ptr_to_record.keys.sort.each do |ptr|
  puts ptr_to_record[ptr]
end
