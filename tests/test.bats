#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=ddev/ddev-typo3-solr

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success

  cp -rf "$DIR/tests" "$TESTDIR"

  run ddev start -y
  assert_success
}

health_checks() {
  echo "Send request from 'web' to the api" >&3
  run ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET 'http://typo3-solr:8983/solr/admin/cores?action=STATUS&wt=json' | jq -r '.responseHeader.status'"
  assert_success
  assert_output "0"

  echo "Apply configuration defined in tests/testdata/config.yaml" >&3
  run ddev solrctl apply tests/testdata/config.yaml
  assert_success
  assert_output --partial "Apply config tests/testdata/config.yaml"

  echo "See expected cores" >&3
  run ddev solrctl list
  assert_success
  assert_output --partial "Found 2 cores"
  assert_output --partial "* core_de"
  assert_output --partial "* core_en"

  echo "Delete/wipe configuration" >&3
  run ddev solrctl wipe
  assert_success
  assert_output --partial "Deleted core 'core_de'"
  assert_output --partial "Deleted core 'core_en'"
  assert_output --partial "Delete all configsets and solr.xml configuration"

  echo "See cores do not exist anymore" >&3
  run ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET 'http://typo3-solr:8983/solr/admin/cores?action=STATUS&wt=json' | jq -r '.status.core_de.name'"
  assert_success
  assert_output "null"
  run ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET 'http://typo3-solr:8983/solr/admin/cores?action=STATUS&wt=json' | jq -r '.status.core_en.name'"
  assert_success
  assert_output "null"

  echo "Test solr command" >&3
  run ddev solr status
  assert_success
  assert_output --partial "No Solr nodes are running"

  echo "Solr Admin UI via HTTP from outside is redirected to HTTP /solr/" >&3
  run curl -sfI http://${PROJNAME}.ddev.site:8983
  assert_success
  assert_output --partial "HTTP/1.1 302"
  assert_output --partial "Location: /solr/"

  echo "Solr Admin UI via HTTPS from outside is redirected to HTTPS /solr/" >&3
  run curl -sfI https://${PROJNAME}.ddev.site:8984
  assert_success
  assert_output --partial "HTTP/2 302"
  assert_output --partial "location: /solr/"

  echo "Solr Admin UI is working from outside" >&3
  run curl -sfL https://${PROJNAME}.ddev.site:8984
  assert_success
  assert_output --partial "Solr Admin"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
