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

  EXPECTED_SOA="briancunnie.gmail.com ns-he.nono.io 2016102202 300 300 300 300"
  # SOA
  QTYPE=SOA QNAME=sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		${EXPECTED_SOA}" ]; then
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
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		${EXPECTED_SOA}" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # NS api.system.10.10.1.80.sslip.io
  QTYPE=NS QNAME=api.system.10.10.1.80.sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-aws.nono.io" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-azure.nono.io" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-gce.nono.io" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		ns-he.nono.io" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # A api.system.10.10.1.80.sslip.io
  QTYPE=A QNAME=api.system.10.10.1.80.sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		10.10.1.80" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # A api.system-10-10-1-80.sslip.io
  QTYPE=A QNAME=api.system.10-11-1-80.sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		10.11.1.80" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # A api.system-10-10-1-80.nonesuch
  QTYPE=A QNAME=api.system.10-11-1-80.nonesuch
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		10.11.1.80" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # A sslip.io
  QTYPE=A QNAME=sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "DATA	${QNAME}	IN	${QTYPE}	300		52.0.56.137" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi
  read -r RESP # clear out 'END'

  # A nonesuch.sslip.io
  QTYPE=A QNAME=nonesuch.sslip.io
  >&2 echo "It responds to our 'Q ${QNAME} IN ${QTYPE}'"
  printf "Q\t${QNAME}\tIN\t${QTYPE}\n"
  read -r RESP
  if [ "${RESP}" == "END" ]; then
    >&2 echo "PASS: received expected '${RESP}'"
  else
    >&2 echo "FAIL: received unexpected '${RESP}'"
  fi

  # clean-up: kill the process under test, remove fifos
  kill $PDNS_PID 2> /dev/null
  rm $TEST_INPUT_FD $TEST_OUTPUT_FD
}

>&2 echo BEGIN testing of $0
test_me
>&2 echo END testing of $0
