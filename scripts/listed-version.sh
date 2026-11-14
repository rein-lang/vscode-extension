#!/bin/sh
# Prints the latest Marketplace version of <publisher>.<name>, or nothing.
set -eu
curl -s -X POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery \
  -H 'Content-Type: application/json' -H 'Accept: application/json;api-version=7.1-preview.1' \
  -d "$(jq -nc --arg id "$1" '{filters:[{criteria:[{filterType:7,value:$id}]}],flags:1}')" |
  jq -r '.results[0].extensions[0].versions[0].version // empty'
