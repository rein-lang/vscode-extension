#!/bin/sh
# Usage: watch-publish.sh <repo>
# A merge to main publishes. Waits for the publish.yml run of the default
# branch head and prints
# {"result": "published" | "not started" | "name taken" | "auth failed" | "other failure"}.
set -eu
repo=$1
here=$(cd "$(dirname "$0")" && pwd)
cd "$repo"
version=$(jq -r .version package.json)
id="$(jq -r .publisher package.json).$(jq -r .name package.json)"
say() { jq -nc --arg r "$1" '{result:$r}'; exit 0; }

[ "$("$here/listed-version.sh" "$id")" = "$version" ] && say published

git fetch -q origin
head=$(git rev-parse "$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)")
run=$(gh run list -w publish.yml -L 10 --json databaseId,headSha \
  -q "[.[] | select(.headSha == \"$head\")][0].databaseId // empty")
[ -n "$run" ] || say "not started"

if gh run watch "$run" --exit-status >/dev/null 2>&1; then
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    [ "$("$here/listed-version.sh" "$id")" = "$version" ] && say published
    sleep 10
  done
  say published # the run passed; the listing can lag a few minutes
fi

log=$(gh run view "$run" --log-failed 2>&1 || true)
echo "$log" | grep -q "already exists in the Marketplace" && say "name taken"
echo "$log" | grep -qiE "oidc|unauthori[sz]ed|401|403|trusted publish" && say "auth failed"
say "other failure"
