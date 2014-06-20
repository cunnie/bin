#!/usr/bin/env ruby
#
#   route53_create_json.rb - creates json to add/delete AWS Route53 records
#
# Usage:
#   
#   route53_create_json.rb > /tmp/route53.json
#   aws route53 change-resource-record-sets --hosted-zone-id Z1OE08QT9BJFFU --change-batch "$(cat /tmp/route53.json)"
#
# Pre-reqs:
#   Set up your creds first:
#     aws configure
#       AKIAJGxxxxxxxxxxxxxx
#       ktnYZdDxxxxxxxxxxxxxxxxxxxxxx/xxxxxxxxxx
#       us-east-1 # NOT us-east-1a!  A superset of zone
#       json
#   OR:
#     export AWS_DEFAULT_REGION=us-east-1
#     export AWS_ACCESS_KEY_ID=AKIAJGxxxxxxxxxxxxxx
#     export AWS_SECRET_ACCESS_KEY=ktnYZdDxxxxxxxxxxxxxxxxxxxxxx/xxxxxxxxxx
#
# JSON Layout
#
# {
#   "Comment": "optional comment about the changes in this change batch request",
#   "Changes": [
#     {
#       "Action": "CREATE"|"DELETE"|"UPSERT",
#       "ResourceRecordSet": {
#         "Name": "DNS domain name",
#         "Type": "SOA"|"A"|"TXT"|"NS"|"CNAME"|"MX"|"PTR"|"SRV"|"SPF"|"AAAA",
#         "TTL": time to live in seconds,
#         "ResourceRecords": [
#           {
#             "Value": "applicable value for the record type"
#           },
#           {...}
#         ]
#       }
#     },
#     {...}
#   ]
# }
#
# Copyright (C) 2014, Pivotal Labs
#
# unlicense
#
# http://unlicense.org
#
require 'json'

res_pools=%w(baboon	badger	bat	bear	bird
  bison	bonobo	booby	camel	cat
  collie	cougar	crab	crane	croc
  deer	dingo	dodo	dog	donkey
  duck	eagle	elephant	falcon	fox
  frog	gerbil	giraffe	goat	goose
  gopher	gorilla	hamster	hippo	horse
  hyena	jackal	jaguar	kiwi	koala
  lemur	leopard	lion	lobster	mole
  moose	mouse	otter	owl	penguin
  pig	pike	poodle	possum	quail
  rabbit	rat	robin	seal	skunk
  sloth	snake	squid	squirrel	tiger
  turtle	vulture	weasel	whale	wolf
  yak	zebra)

octet=-1
changes = res_pools.map do |res_pool|
  octet += 1
  ip_subnet = "10.9.#{octet}" 
  [
    {
      "Action" => "CREATE",
      "ResourceRecordSet" => {
        "Name" =>  "pcf.#{res_pool}.wild.nono.com",
        "Type" => "A",
        "TTL" => 300,
        "ResourceRecords" => [
          { "Value" => "#{ip_subnet}.16"}
        ]
      }
    },
    {
      "Action" => "CREATE",
      "ResourceRecordSet" => {
        "Name" =>  "bosh.#{res_pool}.wild.nono.com",
        "Type" => "A",
        "TTL" => 300,
        "ResourceRecords" => [
          { "Value" => "#{ip_subnet}.17"}
        ]
      }
    },
    {
      "Action" => "CREATE",
      "ResourceRecordSet" => {
        "Name" =>  "*.#{res_pool}.wild.nono.com",
        "Type" => "A",
        "TTL" => 300,
        "ResourceRecords" => [
          { "Value" => "#{ip_subnet}.99"}
        ]
      }
    }
  ]
end

puts JSON.dump(
  "Comment" => "Creating records for my beloved environments",
  "Changes" => changes.flatten
)
