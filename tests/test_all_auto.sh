#!/bin/bash

SRCDIR="$(dirname $0)"
TMPDIR="$(mktemp -d)"
DIR="${TMPDIR}"
TMP="${TMPDIR}"

PATH=/usr/sbin:/sbin:$PATH

export TMPDIR TMP PATH

echo "Killing varnishd instances and varnish-agent instances in 5 seconds"
sleep 5
pkill varnishd
pkill varnish-agent
echo DIR: ${DIR}
mkdir -p ${DIR}/vcl
touch ${DIR}/varnish.pid
echo "Starting varnishd:"
echo
varnishd -f "${SRCDIR}/data/boot.vcl" -P "${DIR}/varnish.pid" -n "$DIR" -a localhost:8081 -T localhost:8082
echo "Starting agent:"
echo
../src/varnish-agent -d -n ${DIR} -p ${DIR}/vcl/ -P ${DIR}/agent.pid &
export VARNISH_PORT=8081
export VARNISHADM_PORT=8082
export N_ARG="-n ${DIR}"
export AGENT_PORT=6085
echo "Settings: "
echo "  VARNISH_PORT: $VARNISH_PORT"
echo "  VARNISHADM_PORT: $VARNISHADM_PORT"
echo "  N_ARG: $N_ARG"
echo "  AGENT_PORT: $AGENT_PORT"
echo
echo Starting tests
$SRCDIR/test_all.sh
ret=$?
echo Stopping varnishd and the agent
kill $(cat ${DIR}/varnish.pid)
kill $(cat ${DIR}/agent.pid)
echo Cleaning up
rm -r ${DIR}
exit $ret
