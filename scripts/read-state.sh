#!/bin/sh
# Prints the release state of a VS Code extension repo as JSON, with the
# fields of State in main.rein.
set -eu
repo=$1
here=$(cd "$(dirname "$0")" && pwd)
pkg="$repo/package.json"
if [ ! -f "$pkg" ] || ! jq -e '.engines.vscode' "$pkg" >/dev/null 2>&1; then
  echo '{"manifest":false}'
  exit 0
fi
name=$(jq -r .name "$pkg")
display=$(jq -r '.displayName // .name' "$pkg")
pub=$(jq -r '.publisher // ""' "$pkg")
version=$(jq -r .version "$pkg")
id="$pub.$name"

name_state=$("$here/check-name.sh" "$name" "$display" "$id" |
  jq -r 'if .name_free and .display_free then "free" else "taken" end')

code=$(curl -s -o /dev/null -w '%{http_code}' "https://marketplace.visualstudio.com/publishers/$pub")
if [ -n "$pub" ] && [ "$code" = 200 ]; then publisher=exists; else publisher=missing; fi

icon_path=$(jq -r '.icon // ""' "$pkg")
if [ -n "$icon_path" ] && [ -f "$repo/$icon_path" ]; then icon=set; else icon=missing; fi

if grep -q "itemName=$id" "$repo/README.md" 2>/dev/null; then readme=marketplace; else readme="local only"; fi

git -C "$repo" fetch -q origin 2>/dev/null || true
branch=$(git -C "$repo" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
if git -C "$repo" show "$branch:.github/workflows/publish.yml" 2>/dev/null | grep -q -- '--oidc'; then
  workflow=merged
else
  workflow=missing
fi

if [ "$("$here/listed-version.sh" "$id")" = "$version" ]; then listing=live; else listing="not live"; fi

jq -nc --arg name "$name_state" --arg publisher "$publisher" --arg icon "$icon" \
  --arg readme "$readme" --arg workflow "$workflow" --arg listing "$listing" \
  '{manifest:true,name:$name,publisher:$publisher,icon:$icon,readme:$readme,workflow:$workflow,listing:$listing}'
