#!/usr/bin/env bash
#
# Originally written by Sam Stephenson for xip.io
set -e
shopt -s nocasematch

#
# Configuration
#
# Increment this timestamp when the contents of the file change.
XIP_TIMESTAMP="2016091100"

# The top-level domain for which the name server is authoritative.
# CHANGEME: change "sslip.io" to your domain
XIP_DOMAIN="sslip.io"

# The public IP addresses (e.g. for the web site) of the top-level domain.
# `A` queries for the top-level domain will return this list of addresses.
# CHANGEME: change this to your domain's webserver's address
XIP_ROOT_ADDRESSES=( "52.0.56.137" )

XIP_NS=( "ns-aws.nono.io" "ns-gce.nono.io" "ns-he.nono.io" )

# These are the MX records for your domain.  IF YOU'RE NOT SURE,
# don't set it at at all (comment it out)--it defaults to no
# MX records.
XIP_MX_RECORDS=(
  "10"  "mx.zoho.com"
  "20"  "mx2.zoho.com"
)

# How long responses should be cached, in seconds.
XIP_TTL=300
XIP_DOMAIN="xip.test"
XIP_MX_RECORDS=( )
XIP_TTL=300

if [ -a "$1" ]; then
  source "$1"
fi

#
# Protocol helpers
#
read_cmd() {
  local IFS=$'\t'
  local i=0
  local arg

  read -ra CMD
  for arg; do
    eval "$arg=\"\${CMD[$i]}\""
    let i=i+1
  done
}

send_cmd() {
  local IFS=$'\t'
  printf "%s\n" "$*"
}

fail() {
  send_cmd "FAIL"
  log "Exiting"
  exit 1
}

read_helo() {
  read_cmd HELO VERSION
  [ "$HELO" = "HELO" ] && [ "$VERSION" = "1" ]
}

read_query() {
  read_cmd TYPE QNAME QCLASS QTYPE ID IP
}

send_answer() {
  local type="$1"
  shift
  send_cmd "DATA" "$QNAME" "$QCLASS" "$type" "$XIP_TTL" "$ID" "$@"
}

log() {
  printf "[xip-pdns:$$] %s\n" "$@" >&2
}


#
# xip.io domain helpers
#
XIP_DOMAIN_PATTERN="(^|\.)${XIP_DOMAIN//./\.}\$"
NS_SUBDOMAIN_PATTERN="^ns-([0-9]+)\$"
IP_SUBDOMAIN_PATTERN="(^|\.)(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))\$"
DASHED_IP_SUBDOMAIN_PATTERN="(^|-|\.)(((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)-){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))\$"

qtype_is() {
  [ "$QTYPE" = "$1" ] || [ "$QTYPE" = "ANY" ]
}

qname_matches_domain() {
  [[ "$QNAME" =~ $XIP_DOMAIN_PATTERN ]]
}

qname_is_root_domain() {
  [ "$QNAME" = "$XIP_DOMAIN" ]
}

extract_subdomain_from_qname() {
  SUBDOMAIN="${QNAME:0:${#QNAME}-${#XIP_DOMAIN}}"
  SUBDOMAIN="${SUBDOMAIN%.}"
}

subdomain_is_ns() {
  [[ "$SUBDOMAIN" =~ $NS_SUBDOMAIN_PATTERN ]]
}

subdomain_is_ip() {
  [[ "$SUBDOMAIN" =~ $IP_SUBDOMAIN_PATTERN ]]
}

subdomain_is_dashed_ip() {
  [[ "$SUBDOMAIN" =~ $DASHED_IP_SUBDOMAIN_PATTERN ]]
}

resolve_ns_subdomain() {
  local index="${SUBDOMAIN:3}"
  echo "${XIP_NS_ADDRESSES[$index-1]}"
}

resolve_ip_subdomain() {
  [[ "$SUBDOMAIN" =~ $IP_SUBDOMAIN_PATTERN ]] || true
  echo "${BASH_REMATCH[2]}"
}

resolve_dashed_ip_subdomain() {
  [[ "$SUBDOMAIN" =~ $DASHED_IP_SUBDOMAIN_PATTERN ]] || true
  echo "${BASH_REMATCH[2]//-/.}"
}

answer_soa_query() {
  send_answer "SOA" "admin.$XIP_DOMAIN ns-1.$XIP_DOMAIN $XIP_TIMESTAMP $XIP_TTL $XIP_TTL $XIP_TTL $XIP_TTL"
}

answer_ns_query() {
  local i=1
  local ns_address
  for ns in "${XIP_NS[@]}"; do
    send_answer "NS" "$ns"
  done
}

answer_root_a_query() {
  local address
  for address in "${XIP_ROOT_ADDRESSES[@]}"; do
    send_answer "A" "$address"
  done
}

answer_mx_query() {
  set -- "${XIP_MX_RECORDS[@]}"
  while [ $# -gt 1 ]; do
    send_answer "MX" "$1	$2"
  shift 2
  done
}

answer_subdomain_a_query_for() {
  local type="$1"
  local address="$(resolve_${type}_subdomain)"
  if [ -n "$address" ]; then
    send_answer "A" "$address"
  fi
}


#
# PowerDNS pipe backend implementation
#
trap fail err
read_helo
send_cmd "OK" "xip.io PowerDNS pipe backend (protocol version 1)"

while read_query; do
  log "Query: type=$TYPE qname=$QNAME qclass=$QCLASS qtype=$QTYPE id=$ID ip=$IP"

      if qtype_is "SOA"; then
        answer_soa_query
      elif qtype_is "NS"; then
        answer_ns_query
      elif qtype_is "A"; then
        answer_root_a_query
      elif qtype_is "MX"; then
        answer_mx_query
      elif qtype_is "A"; then
        extract_subdomain_from_qname
        if subdomain_is_dashed_ip; then
          answer_subdomain_a_query_for dashed_ip
        elif subdomain_is_ip; then
          answer_subdomain_a_query_for ip
        fi
      fi

  send_cmd "END"
done
