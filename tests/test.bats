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

health_checks_standalone() {
  echo "Send request from 'web' to the api" >&3
  run ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET 'http://typo3-solr:8983/solr/admin/cores?action=STATUS&wt=json' | jq -r '.responseHeader.status'"
  assert_success
  assert_output "0"

  echo "is-solrcloud returns false" >&3
  run ddev solrctl-worker is-solrcloud
  assert_success
  assert_output "false"

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

  echo "Apply configuration with existing cores, do not fail on existing" >&3
  run ddev solrctl apply tests/testdata/config.yaml
  assert_success
  assert_output --partial "Core with name 'core_de' already exists"
  assert_output --partial "Core with name 'core_en' already exists"

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

health_checks_solrcloud() {
  echo "SolrCloud API up" >&3
  run ddev exec "curl -s --fail 'http://typo3-solr:8983/solr/admin/collections?action=LIST&wt=json' | jq -r '.responseHeader.status'"
  assert_success
  assert_output "0"

  echo "is-solrcloud returns true" >&3
  run ddev solrctl-worker is-solrcloud
  assert_success
  assert_output "true"

  echo "Apply config in SolrCloud mode" >&3
  run ddev solrctl apply tests/testdata/config.yaml
  assert_success
  assert_output --partial "Apply config tests/testdata/config.yaml"
  assert_output --partial "SolrCloud mode detected"
  assert_output --partial "SolrCloud ready with typo3lib"
  assert_output --partial "Configset 'example_configset_english' uploaded"
  assert_output --partial "Configset 'example_configset_german' uploaded"
  assert_output --partial "Collection 'core_en' created"
  assert_output --partial "Collection 'core_de' created"

  echo "Managed stopwords seeded for collections" >&3
  assert_output --partial "Seeded"
  assert_output --partial "stopwords"

  echo "Configsets present in ZooKeeper" >&3
  run ddev exec "curl -s 'http://typo3-solr:8983/solr/admin/configs?action=LIST&wt=json' | jq -r '.configSets[]'"
  assert_success
  assert_output --partial "example_configset_english"
  assert_output --partial "example_configset_german"

  echo "List shows 2 collections in SolrCloud mode" >&3
  run ddev solrctl list
  assert_success
  assert_output --partial "Found 2 collections (SolrCloud mode)"
  assert_output --partial "* core_en"
  assert_output --partial "* core_de"

  echo "Apply again is idempotent" >&3
  run ddev solrctl apply tests/testdata/config.yaml
  assert_success
  assert_output --partial "Configset 'example_configset_english' already exists"
  assert_output --partial "Configset 'example_configset_german' already exists"
  assert_output --partial "Collection 'core_en' already exists"
  assert_output --partial "Collection 'core_de' already exists"

  echo "Wipe removes all collections and configsets" >&3
  run ddev solrctl wipe
  assert_success
  assert_output --partial "SolrCloud mode"
  assert_output --partial "Deleted collection 'core_de'"
  assert_output --partial "Deleted collection 'core_en'"
  assert_output --partial "Deleted configset 'example_configset_english'"
  assert_output --partial "Deleted configset 'example_configset_german'"

  echo "No collections after wipe" >&3
  run ddev exec "curl -s 'http://typo3-solr:8983/solr/admin/collections?action=LIST&wt=json' | jq -r '.collections | length'"
  assert_success
  assert_output "0"

  echo "No user configsets after wipe" >&3
  run ddev exec "curl -s 'http://typo3-solr:8983/solr/admin/configs?action=LIST&wt=json' | jq -r '[.configSets[] | select(startswith(\"_\") | not)] | length'"
  assert_success
  assert_output "0"

  echo "Solr Admin UI accessible in SolrCloud mode" >&3
  run curl -sfL https://${PROJNAME}.ddev.site:8984
  assert_success
  assert_output --partial "Solr Admin"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory (Standalone)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks_standalone
}

# bats test_tags=release
@test "install from release (Standalone)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks_standalone
}

@test "install from directory (SolrCloud)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with SolrCloud mode, project ${PROJNAME} in $(pwd)" >&3
  run ddev dotenv set .ddev/.env.solr --solr-mode="solrcloud"
  assert_success
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks_solrcloud
}

# bats test_tags=release
@test "install from release (SolrCloud)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with SolrCloud mode, project ${PROJNAME} in $(pwd)" >&3
  run ddev dotenv set .ddev/.env.solr --solr-mode="solrcloud"
  assert_success
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks_solrcloud
}
