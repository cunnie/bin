#!/usr/bin/env ruby

# typical use:
# dig @nono.io axfr nono.io. | aaaa_to_ptr.rb | sudo tee /usr/local/etc/namedb/primary/0.0.1.0.6.4.6.0.1.0.6.2.IP6.arpa
#
# Typical axfr output:
#
# www.nono.io.		300	IN	A	78.46.204.247
# www.nono.io.		300	IN	AAAA	2a01:4f8:c17:b8f::2

require 'ipaddr'

puts <<~AXFR
  $TTL 3h
  @ SOA avalon.nono.io. yoyo.nono.io. #{Time.now.to_i} 1d 12h 1w 3h
          ; Serial, Refresh, Retry, Expire, Neg. cache TTL

          NS      atom.nono.io.
AXFR

# For dumping out IPv6 reverse-lookup files
class IPv6Hostname
  attr_accessor :ip, :hostname

  def initialize(ip, hostname)
    @ip = ip
    @hostname = hostname
  end

  def <=>(other)
    @ip <=> other.ip
  end
end

ipv6_hostnames = []
$stdin.read.split("\n").each do |line|
  next unless line.match?(/\tAAAA\t/)

  fields = line.split(' ')
  next unless fields[4].match?(/^2601:646:100:/)

  fields[0].gsub!(/^\*\./, '') # '*' (wildcards) cause `named` to fail to load zone
  ipv6_hostnames << IPv6Hostname.new(IPAddr.new(fields[4]), fields[0])
end

ipv6_hostnames.sort.each do |ip6|
  puts "#{ip6.ip.ip6_arpa}.\tPTR\t#{ip6.hostname}"
end
