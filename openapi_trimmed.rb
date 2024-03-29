#!/usr/bin/env ruby

# this file takes in an OPENAPI JSON-formatted file
# and pulls in all the dependent definitions
#
# Typical use:
#
# openapi_trimmed.rb \
#   --openapi ~/workspace/bosh-vsphere-cpi-release/src/vsphere_cpi/data/nsxt_manager_api/nsxt_manager_api.json
#   --endpoints endpoints.txt
#
# Where the endpoints.txt file is a list of endpoints, one per line, e.g.
#
#  /logical-ports
#  /ns-groups/{ns-group-id}/effective-directory-group-members
#

require 'json'
require 'optparse'

class OpenAPIChugger
  def initialize(openapi, endpoints)
    @openapi = openapi
    @endpoints = endpoints
    @models = []
    @re = %r{#/definitions/(.*)}
  end

  def info
    @openapi['info']
  end

  def definitions
    @endpoints.each do |endpoint|
      iterate(@openapi['paths'][endpoint])
    end
  end

  def models
    @models.sort.each do |model|
      puts "\"#{model}\","
    end
  end

  def iterate_model(model)
    return if @models.include?(model) # do we already have this model?

    return unless @openapi['definitions'].key?(model) # Is this really a model or just some weird ENUM?

    @models << model
    iterate(@openapi['definitions'][model])
  end

  def iterate(hash_array_or_string)
    hash_array_or_string.each do |k, v|
      # If v is nil, an array is being iterated and the value is k.
      # If v is not nil, a hash is being iterated and the value is v.
      value = v || k

      if k == 'enum' && v.is_a?(Array) # 'enum' sometimes list necessary models
        v.each do |model|
          iterate_model(model)
        end
      elsif value.is_a?(Hash) || value.is_a?(Array)
        iterate(value)
      elsif value.is_a?(Array)
        iterate(value)
      elsif value.is_a?(String) && @re.match(value)
        model = @re.match(value)[1]
        iterate_model(model)
      end
    end
  end
end

endpoints = []
openapi = {}

OptionParser.new do |parser|
  parser.on('--endpoints=endpoints_file') do |endpoints_file|
    File.open(endpoints_file).each do |line|
      endpoints << line.chop!
    end
  end
  parser.on('--openapi=openapi_file') do |openapi_file|
    openapi = JSON.parse(File.read(openapi_file))
  end
end.parse!

x = OpenAPIChugger.new(openapi, endpoints)
x.definitions
x.models
