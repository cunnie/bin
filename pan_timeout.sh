#!/usr/bin/env bash -x

# ssh command:
# - port 2222 is the CF ssh-proxy port
# - turn off password auth so it doesn't hang on password entry
# - turn off key checking so it doesn't hang waiting for key
SSH_CMD="ssh \
 -p 2222 \
 -o PasswordAuthentication=no \
 -o StrictHostKeyChecking=no \
 api.run.haas-104.pez.pivotal.io"

# Start with a ten-minute timeout
TIMEOUT_SECS=600

while :; do
 $($SSH_CMD)
 RC=$?
 if [ $RC -eq 255 ]; then
   # no proxying was attempted
   echo "Timeout: $TIMEOUT_SECS, proxying not attempted"
 elif [ $RC -ne 0 ]; then
   # proxying was attempted
   echo "Timeout: $TIMEOUT_SECS, proxying attempted"
   break
 else
   echo "Timeout: $TIMEOUT_SECS, shouldn't get here"
 fi
 TIMEOUT_SECS=$(( TIMEOUT_SECS + 120 ))
 echo "Upcoming timeout: $TIMEOUT_SECS"
 sleep $TIMEOUT_SECS
done