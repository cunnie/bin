#!/usr/bin/env ruby
#
# This code is meant to be run on a BOSH Director when troubleshooting
# intermittent TLS errors when communicating with, say, a vSphere vCenter.
#
# export PATH=/var/vcap/packages/ruby-3.1/bin:$PATH
# export GEM_PATH=/var/vcap/packages/vsphere_cpi/vendor/bundle/ruby/3.1.0/
#
ENV['GEM_PATH'] = "/var/vcap/packages/vsphere_cpi/vendor/bundle/ruby/3.1.0#{ENV['GEM_PATH']}"
require 'httpclient'

successful_attempts = 0
failed_attempts = 0
# from https://github.com/recurly/recurly-client-ruby/issues/425
puts "OpenSSL version: #{OpenSSL::OPENSSL_VERSION}"
puts "OpenSSL library version: #{OpenSSL::OPENSSL_LIBRARY_VERSION}"
loop do
  begin
    backing_client = HTTPClient.new
    backing_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    backing_client.get('https://nsx.nono.io')
    successful_attempts += 1
  rescue StandardError => e
    failed_attempts += 1
    puts e.message
  end
  puts "successful attempts: #{successful_attempts}; failed attempts: #{failed_attempts}; success rate: #{successful_attempts * 100 / (successful_attempts + failed_attempts)}%"
  sleep 5
end
