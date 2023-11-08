#!/usr/bin/env bats

setup_suite() {
    export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    set -eu -o pipefail
    export TESTDIR=~/tmp/test-apache-solr-addon
    mkdir -p $TESTDIR
    export PROJNAME=addon-apache-solr
    export DDEV_NON_INTERACTIVE=true
    ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
    cd "${TESTDIR}"
    ddev config --project-name=${PROJNAME}
    ddev start -y >/dev/null

    cd "${TESTDIR}"
    echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
    ddev get "${DIR}/.."
    ddev restart
}

teardown_suite() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}
