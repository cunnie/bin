#!/bin/bash
#
#  pdns_pipe_spec.sh
#  - doesn't take arguments
#  - assume `pdns_pip.sh` is in same directory
#  - assume current directory is writable (fifos/named pipes)
#  bosh int --path /pdns_pipe ~/workspace/sslip.io/conf/sslip.io+nono.io.yml > ~/bin/pdns_pipe.sh

set_up() {
  TEST_INPUT_FD=/tmp/pdns_pipe.stdin.$$
  TEST_OUTPUT_FD=/tmp/pdns_pipe.stdout.$$
  mkfifo $TEST_INPUT_FD $TEST_OUTPUT_FD
  ${0/_spec/} < $TEST_OUTPUT_FD > $TEST_INPUT_FD &
  PDNS_PID=$!
  exec -- > $TEST_OUTPUT_FD < $TEST_INPUT_FD

  >&2 echo It responds to our 'HELO 1' with 'OK'
  printf "HELO\t1\n"
  read -ra RESP

  # HELO
  if [ ${RESP[0]} == "OK" ]; then
    >&2 echo "PASS: received expected '${RESP[0]}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP[0]}'"
  fi
}

pass() {
    >&2 echo "PASS: received expected '$1'"
}

fail() {
    >&2 echo "FAIL: received unexpected '$1'"
    exit 1
}

# PowerDNS response ends with 'END'
test_end() {
  read -r RESP
  if [ "${RESP}" == "END" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_soa_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		${EXPECTED_SOA}" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_soa() {
  EXPECTED_SOA="briancunnie.gmail.com ns-he.nono.io 2018092000 300 300 300 300"
  QTYPE=SOA QNAME=$1
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  test_soa_resp
}

test_ns_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-aws.nono.io" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-azure.nono.io" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-gce.nono.io" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-vultr.nono.io" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_ns() {
  QTYPE=NS QNAME=$1
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  test_ns_resp
}

test_mx_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		10	mail.protonmail.ch" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_mx() {
  QTYPE=MX QNAME=$1
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  test_mx_resp
}

test_txt_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		protonmail-verification=ce0ca3f5010aa7a2cf8bcc693778338ffde73e26" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_txt() {
  QTYPE=TXT QNAME=$1
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  test_txt_resp
}

test_a_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		${EXPECTED}" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_a() {
  QTYPE=A QNAME=$1 EXPECTED=$2
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  if [ "${EXPECTED}" == "" ]; then
    return
  else
    test_a_resp
  fi
}

test_aaaa_resp() {
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		${EXPECTED}" ]; then
    pass "${RESP}"
  else
    fail "${RESP}"
  fi
}

test_aaaa() {
  QTYPE=AAAA QNAME=$1 EXPECTED=$2
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  if [ "${EXPECTED}" == "" ]; then
    return
  else
    test_aaaa_resp
  fi
}

test_any() {
  QTYPE=ANY QNAME=$1 EXPECTED=$2
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  QTYPE=SOA test_soa_resp
  QTYPE=NS test_ns_resp
  QTYPE=TXT test_txt_resp
  QTYPE=MX test_mx_resp
  if [ "${EXPECTED}" == "" ]; then
    return
  fi
  if [[ "${EXPECTED}" =~ \. ]]; then
    QTYPE=A test_a_resp
    return
  fi
  if [[ "${EXPECTED}" =~ : ]]; then
    QTYPE=AAAA test_aaaa_resp
    return
  fi
}

test_excluded_domain() {
  QTYPE=ANY QNAME=$1
  >&2 echo "It doesn't respond to our excluded domain, 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  # we don't read a response, for there should be no records
}

>&2 echo BEGIN testing of $0
set_up

test_soa sslip.io
test_end

test_soa some-random-domain.com
test_end

test_excluded_domain nono.io
test_end

test_soa api.system.10.10.1.80.sslip.io
test_end

test_ns sslip.io
test_end

test_ns api.system.10.10.1.80.sslip.io
test_end

test_ns api.system.10.10.1.80.sslip.io
test_end

test_mx sslip.io
test_end

test_txt sslip.io
test_end

test_a sslip.io 78.46.204.247
test_end

test_a sSliP.io 78.46.204.247
test_end

test_a localhost.sslip.io 127.0.0.1
test_end

test_a nono.io.192.168.168.168.sslip.io 192.168.168.168
test_end

test_a api.system.192-168-168-168.sslip.io 192.168.168.168
test_end

test_a api.system.255-255-255-255.sslip.io 255.255.255.255
test_end

test_a api.system.255.255.255.256.sslip.io ""
test_end

test_a api.system.255-255-255-256.sslip.io ""
test_end

test_a nonesuch.sslip.io ""
test_end

test_a api.system.192.168.168.168.some.random.com 192.168.168.168
test_end

test_a api.system.192-168-168-168.some.random.com 192.168.168.168
test_end

test_aaaa sslip.io 2a01:4f8:c17:b8f::2
test_end

test_aaaa SsLiP.Io 2a01:4f8:c17:b8f::2
test_end

test_aaaa localhost.sslip.io ::1
test_end

test_aaaa --.sslip.io ::
test_end

test_aaaa api.--.sslip.io ::
test_end

test_aaaa --1.sslip.io ::1
test_end

test_aaaa 2a01-4f8-c17-b8f--2.sslip.io 2a01:4f8:c17:b8f::2
test_end

test_aaaa fe80--10cc-ddb8-cbad-bdf1.sslip.io fe80::10cc:ddb8:cbad:bdf1
test_end

test_aaaa 2a01-4f8-c17-b8f--2.sslip.io 2a01:4f8:c17:b8f::2
test_end

test_aaaa api.system.2a01-4f8-c17-b8f--2.sslip.io 2a01:4f8:c17:b8f::2
test_end

test_aaaa api.system.2a01-4f8-c17-b8f--xxxx.sslip.io ""
test_end

test_aaaa 2a01-4f8-c17-b8f--2.some.random.com 2a01:4f8:c17:b8f::2
test_end

test_aaaa api.system.2a01-4f8-c17-b8f--2.some.random.com 2a01:4f8:c17:b8f::2
test_end

test_any api.system.255-255-255-255.sslip.io 255.255.255.255
test_end

test_any api.system.255.255.255.256.sslip.io ""
test_end

test_any api.system.2a01-4f8-c17-b8f--2.sslip.io 2a01:4f8:c17:b8f::2
test_end

>&2 echo END testing of $0
# clean-up: kill the process under test, remove fifos
kill $PDNS_PID 2> /dev/null
rm $TEST_INPUT_FD $TEST_OUTPUT_FD
