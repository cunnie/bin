#!/bin/bash

TESTBED_FILE=/tmp/testbed.$$.txt
DATACENTER=wdc
USER=svc.tas-anycloud NIMBUS_LOCATION=$DATACENTER nimbus-ctl --testbed list > $TESTBED_FILE
sort -k 2 < $TESTBED_FILE | # sort by testbed name
  grep -v "^ " | # remove the VMs, keep only the testbed info
  grep -v "lease expires at unknown" | # ignore zombie testbeds which have no VMs
  cut -b 16-512 | # remove weird & useless datacenter info
  sed 's=(ID: .......),.*==' | # remove everything but the testbed name
  awk -v DATACENTER=$DATACENTER '
BEGIN { OLD_TESTBED=""; OLD_TESTBED_TIMESTAMP="" }
{
  CURRENT_TESTBED=gensub(/-[0-9]+$/, "", "")
  CURRENT_TESTBED_TIMESTAMP = gensub(/.*-([0-9]+)$/, "\\1", "")
  if ( OLD_TESTBED != "" ) {
     if ( OLD_TESTBED != CURRENT_TESTBED ) {
        print "# skipping " OLD_TESTBED "-" OLD_TESTBED_TIMESTAMP " because it is the most recent"
     } else {
        print "USER=svc.tas-anycloud NIMBUS_LOCATION=" DATACENTER " nimbus-ctl --testbed kill " OLD_TESTBED "-" OLD_TESTBED_TIMESTAMP
     }
  }
  OLD_TESTBED = CURRENT_TESTBED
  OLD_TESTBED_TIMESTAMP = CURRENT_TESTBED_TIMESTAMP
}
END { print "# skipping " OLD_TESTBED "-" OLD_TESTBED_TIMESTAMP " because it is the most recent" }
'
