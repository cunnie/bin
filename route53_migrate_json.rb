#!/usr/bin/env ruby
#
#   route53_migrate_json.rb - creates json to add AWS Route53 records
#     based on json dumped from a different domain (usually subdomain)
#
# Usage:
#   
#   aws route53 list-resource-record-sets --hosted-zone-id ZQVZ2XXXXXXXX | /tmp/route53_migrate_json.rb > /tmp/sausage.json
#   aws route53 change-resource-record-sets --hosted-zone-id Z1OE0YYYYYYYYY --change-batch "$(cat /tmp/sausage.json)"
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

inbound = JSON.parse(STDIN.read)
outbound = {
  "Comment" => "Migrating my beloved records",
  "Changes" => []
}

resource_records = inbound['ResourceRecordSets']

resource_records.each do |record|
  record_type = record.fetch('Type')
  next if record_type == 'NS' or record_type == 'SOA'
  outbound['Changes'] << { 
    "Action" => "CREATE",
    "ResourceRecordSet" => record
  }
end

puts JSON.pretty_generate outbound
