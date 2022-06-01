#!/usr/bin/env zsh

set -ex

cf create-security-group cats-sg <(echo '[{"protocol":"tcp","destination":"10.0.244.255","ports":"80","description":"cats-sg"}]') || true

while : ; do
  SLEEP=$(( RANDOM % 80 ))
  SUCCESS=0
  FAIL=0
  for COUNT in 1 2 3 4 5; do
    cf unbind-security-group cats-sg system system
    cf delete -f cats-app
    cf push cats-app -b go_buildpack -m 256M \
      -p ~/workspace/cf-acceptance-tests/assets/proxy \
      -f ~/workspace/cf-acceptance-tests/assets/proxy/manifest.yml
    # 10.0.244.255 is a hard-coded random IP address that's not tied to a VM or container
    cf run-task cats-app --command "curl --fail --connect-timeout 10 10.0.244.255:80" --name woof
    # It takes 2 seconds for the curl's output to hit the logs; we wait 4 seconds
    sleep 4
    if ! ( cf logs cats-app --recent | grep -v "Connection refused" ); then
      echo "Didn't get the logs!"
      exit 1
    fi # look for "Failed to connect" "Connection refused"
    cf bind-security-group cats-sg system --space system
    sleep $SLEEP
    cf restart cats-app
    cf run-task cats-app --command "curl --fail --connect-timeout 10 10.0.244.255:80" --name woof
    # It takes 2 seconds for the curl's output to hit the logs; we wait 4 seconds
    # And then we add the 10-second timeout for a total of 14  seconds
    sleep 14
    cf logs cats-app --recent
    if (cf logs cats-app --recent | grep -q "Connection timed out"); then # look for "Connection timed out"
      SUCCESS=$(( SUCCESS + 1 ))
    else
      FAIL=$(( FAIL + 1 ))
    fi
  done
  echo "SLEEP $SLEEP seconds, $SUCCESS successes, $FAIL failures"
done

