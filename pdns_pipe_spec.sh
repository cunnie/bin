#!/bin/bash
#
#  pdns_pipe_spec.sh
#  - doesn't take arguments
#  - assume `pdns_pip.sh` is in same directory
#  - assume current directory is writable (fifos/named pipes)

test_me() {
  TEST_INPUT_FD=/tmp/input.$$
  TEST_OUTPUT_FD=/tmp/output.$$
  mkfifo $TEST_INPUT_FD $TEST_OUTPUT_FD
  ${0/_spec/} < $TEST_OUTPUT_FD > $TEST_INPUT_FD 2> /dev/null &
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

  # SOA
  QTYPE=SOA QNAME=sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		admin.xip.test ns-1.xip.test 2016091100 300 300 300 300" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # SOA api.system.10.10.1.80.sslip.io
  QTYPE=SOA QNAME=api.system.10.10.1.80.sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		admin.xip.test ns-1.xip.test 2016091100 300 300 300 300" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'


  # clean-up: kill the process under test, remove fifos
  kill $PDNS_PID 2> /dev/null
  rm $TEST_INPUT_FD $TEST_OUTPUT_FD
}

>&2 echo BEGIN testing of $0
test_me
>&2 echo END testing of $0
