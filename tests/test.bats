#!/bin/bash


@test "Send request from 'web' to the api" {
  result="$(ddev exec "curl --fail -H 'Content-Type: application/json' -X GET \"http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json\"")"
  status=$(echo "$result" | yq '.responseHeader.status')

   [ $status -eq 0 ]
}

@test "Apply configuration defined in tests/testdata/config.yaml" {
  ddev solrctl apply tests/testdata/config.yaml

  [ "$?" -eq 0 ]
}

@test "See expected cores" {
  result=$(ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET  \"http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json\"")
  echo "$result"

  core_de_name=$(echo $result | jq -r -c -S '.status.core_de.name' 2>/dev/null)
  core_en_name=$(echo $result | jq -r -c -S '.status.core_en.name' 2>/dev/null)

  [ "$core_de_name" == "core_de" ]
  [ "$core_en_name" == "core_en" ]
}

@test "Delete/wipe configuration" {
  ddev solrctl wipe
  ddev restart

  [ "$?" -eq 0 ]
}

@test "See cores do not exist anymore" {
  result=$(ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json")
  echo "$result"
  core_de_name=$(echo $result | jq -r -c -S '.status.core_de.name' 2>/dev/null)
  core_en_name=$(echo $result | jq -r -c -S '.status.core_en.name' 2>/dev/null)

  [ ! "$core_de_name" == "core_de" ]
  [ ! "$core_en_name" == "core_en" ]
}

@test "See files and folders removed" {
  [ ! -d "$TESTDIR/.ddev/apache-solr/data/configsets/configset" ]
  [ ! -f "$TESTDIR/.ddev/apache-solr/data/solr.xml" ]
  [ ! -d "$TESTDIR/.ddev/apache-solr/data/configsets/core_de" ]
  [ ! -d "$TESTDIR/.ddev/apache-solr/data/configsets/core_en" ]
}

@test "Test solr command" {
  ddev solr status

  [ "$?" -eq 0 ]
}
