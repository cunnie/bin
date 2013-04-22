#!/bin/bash
while :; do
  /usr/bin/chromium --kiosk
  RC=$?
  sleep 10
  logger "Restarting Chromium, exited with $RC"
done
