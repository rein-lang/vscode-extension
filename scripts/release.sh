#!/bin/sh
# Usage: release.sh <repo>
# Pushes tag v<version> on the default branch, waits for publish.yml, and
# prints {"result": "published" | "name taken" | "auth failed" | "other failure"}.
set -eu
repo=$1
here=$(cd "$(dirname "$0")" && pwd)
cd "$repo"
version=$(jq -r .version package.json)
id="$(jq -r .publisher package.json).$(jq -r .name package.json)"
tag="v$version"
say() { jq -nc --arg r "$1" '{result:$r}'; exit 0; }

[ "$("$here/listed-version.sh" "$id")" = "$version" ] && say published

# The gh helper gives git the gh login, which can push to repos with workflows.
push() { git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push -q origin "$@"; }
git fetch -q origin
head=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
# The version is not live, so nothing was published from an old tag: move it.
if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
  push ":refs/tags/$tag"
fi
git tag -f "$tag" "$head" >/dev/null
push "$tag"

run=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
  sleep 5
  run=$(gh run list -w publish.yml -L 5 --json databaseId,headBranch \
    -q "[.[] | select(.headBranch == \"$tag\")][0].databaseId // empty")
  [ -n "$run" ] && break
done
[ -n "$run" ] || say "other failure"

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
