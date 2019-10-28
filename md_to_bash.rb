#!/usr/bin/env ruby
#
# md_to_bash.rb < ~/workspace/acme.sh.wiki/dnsapi.md
#
# This code generates bash-script to use in my
# <https://github.com/cunnie/lets-encrypt-concourse-job> repo.
#
# The bash script identifies the [DNS
# API](https://github.com/Neilpang/acme.sh/wiki/dnsapi) to use based on
# the shell variables. For example, if the user has set the `CF_Token`
# variable, then we must use the `dns_cf` API.
#
# This is for Neil Pang's [acme.sh](https://github.com/Neilpang/acme.sh)
# Let's Encrypt client
#
apis = []
api = ''
env_vars = []

class Api
  @@longest_env_var = 0
  @@longest_api = 0

  def initialize(env_vars: [], api: '')
    @env_vars = env_vars
    @api = api
    @@longest_api = api.length if api.length > @@longest_api
    env_vars.each do |env_var|
      @@longest_env_var = env_var.length if env_var.length > @@longest_env_var
    end
  end

  #   [ "$CF_Key"   ] && DNS_CHALLENGE_TYPE=dns_cf && return
  def emit
    @env_vars.each do |env_var|
      print "  [ \"$#{env_var}\""
      print ' ' * (@@longest_env_var - env_var.length)
      print " ] && DNS_CHALLENGE_TYPE=#{@api}"
      print ' ' * (@@longest_api - @api.length)
      print " && return\n"
    end
  end
end

def get_env_var(line)
  line.split.each do |word|
    return word.split(/=/)[0] if word =~ /=/
  end
end

def get_api(line)
  line.split.each do |word|
    next unless word =~ /^dns_/
    return nil if %w[dns_myapi dns_mydevil].include?(word)

    return word
  end
end

STDIN.read.split("\n").each do |line|
  env_vars << get_env_var(line) if line.match?(/^export/)
  next unless line.include? '--issue' and api == ''

  api = get_api line
  unless api.nil?
    apis << Api.new(env_vars: env_vars, api: api) if api
  end
  api = ''
  env_vars = []
end

apis.each(&:emit)
