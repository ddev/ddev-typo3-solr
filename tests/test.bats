#!/bin/bash

@test "Send request from 'web' to the api" {
    result="$(ddev exec "curl --fail -H 'Content-Type: application/json' -X GET \"http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json\"")"
    status=$(echo "$result" | yq '.responseHeader.status')

    [ "$status" -eq 0 ]
}

@test "Apply configuration defined in tests/testdata/config.yaml" {
    run ddev solrctl apply tests/testdata/config.yaml;

    [ "$status" -eq 0 ]
    [[ "$output" == *"Apply config tests/testdata/config.yaml"* ]]
}

@test "See expected cores" {
    result=$(ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET  \"http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json\"")

    core_de_name=$(echo $result | jq -r -c -S '.status.core_de.name' 2>/dev/null)
    core_en_name=$(echo $result | jq -r -c -S '.status.core_en.name' 2>/dev/null)

    echo $result
    echo $core_de_name

    [ "$core_de_name" == "core_de" ]
    [ "$core_en_name" == "core_en" ]
}

@test "Delete/wipe configuration" {
    run ddev solrctl wipe

    [[ "$output" == *"Core 'core_de' deleted"* ]]
    [[ "$output" == *"Core 'core_en' deleted"* ]]
}

@test "See cores do not exist anymore" {
    run ddev exec "curl -s --fail -H 'Content-Type: application/json' -X GET http://apache-solr:8983/solr/admin/cores?action=STATUS&wt=json"
    core_de_name=$(echo $output | jq -r -c -S '.status.core_de.name' 2>/dev/null)
    core_en_name=$(echo $output | jq -r -c -S '.status.core_en.name' 2>/dev/null)

    [ "$core_de_name" == "null" ]
    [ "$core_en_name" == "null" ]
}

@test "Test solr command" {
  run ddev solr status

  [ "$status" -eq 0 ]
  [[ "$output" == *"Found 1 Solr nodes:"* ]]
}
