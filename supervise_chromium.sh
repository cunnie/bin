#!/bin/bash
while :; do
  /usr/bin/chromium --kiosk
  RC=$?
  sleep 30
  logger "Restarting Chromium, exited with $RC"
done
