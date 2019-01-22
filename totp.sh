#!/usr/bin/env bash
#
# Script to display QR codes containing TOTP secrets to be scanned in
# by an authenticator app.
#
# invocation: totp.sh < file_of_urls_one_per_line
#
# e.g. lpass show --note totp.txt | totp.sh

while read URL; do
  [ -z "$URL" ] || qrencode -o - -t ANSI $URL
done

