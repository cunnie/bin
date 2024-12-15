#!/bin/bash -e

while read -r first_name last_name; do
  if ! grep -qi "$first_name.*$last_name" 2024{,_new}.csv; then 
    echo $first_name $last_name
  fi
done < /tmp/junk.txt
