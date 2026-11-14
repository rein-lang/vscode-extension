#!/bin/sh
# Usage: check-name.sh <name> <displayName> [own publisher.name]
# Prints {"name_free":bool,"display_free":bool}. Marketplace extension names
# are unique across all publishers; the extension's own listing does not count.
set -eu
name=$1 display=$2 own=${3:-}
q() {
  curl -s -X POST https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery \
    -H 'Content-Type: application/json' -H 'Accept: application/json;api-version=7.1-preview.1' \
    -d "$(jq -nc --arg v "$1" '{filters:[{criteria:[{filterType:10,value:$v},{filterType:8,value:"Microsoft.VisualStudio.Code"}],pageSize:100}],flags:0}')"
}
# ponytail: search returns the top 100 hits; an exact match ranks first in practice.
count() { # <search> <field> <value>
  q "$1" | jq --arg f "$2" --arg v "$3" --arg own "$own" '
    [.results[0].extensions[]
     | select((.[$f] | ascii_downcase) == ($v | ascii_downcase))
     | select(("\(.publisher.publisherName).\(.extensionName)" | ascii_downcase) != ($own | ascii_downcase))]
    | length'
}
n=$(count "$name" extensionName "$name")
d=$(count "$display" displayName "$display")
jq -nc --argjson n "$n" --argjson d "$d" '{name_free:($n==0),display_free:($d==0)}'
