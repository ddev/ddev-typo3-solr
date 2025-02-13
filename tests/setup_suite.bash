#!/usr/bin/env bats

setup_suite() {
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  set -eu -o pipefail
  export TESTDIR=~/tmp/test-typo3-solr-addon
  mkdir -p $TESTDIR
  export PROJNAME=test-addon-typo3-solr
  export DDEV_NON_INTERACTIVE=true

  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME}
  ddev start -y >/dev/null

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get "${DIR}/.."
  cp -rf "$DIR" "$TESTDIR/"
  ddev restart -y >/dev/null
}

teardown_suite() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && sudo rm -rf ${TESTDIR}
}
