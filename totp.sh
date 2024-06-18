#!/usr/bin/env bash
#
# Script to display QR codes containing TOTP secrets to be scanned in
# by an authenticator app.
#
# Make sure you've done `brew install qrencode`
#
# invocation: totp.sh < file_of_urls_one_per_line
#
# Typical line:
#
#   otpauth://totp/GitHub:brian.cunnie@broadcom.com?secret=b2............f4
#
# e.g. lpass show --note totp.txt | totp.sh

while read URL; do
  if [[ "${URL}" =~ "#" ]]; then
    echo ignoring "${URL}"
    continue
  fi
  echo QR code for $URL
  [ -z "${URL}" ] || qrencode -o - -t ANSI "${URL}"
done
