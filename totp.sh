#!/usr/bin/env bash -x

set -- $(lpass show --note totp.txt)

while [ $# -gt 2 ]; do
  DESCRIPTION=$1
  SECRET=$2

  qrencode -o - -t ANSI otpauth://totp/$DESCRIPTION?secret=$SECRET
  echo $URI
  shift 2
done

