#!/bin/sh
# Usage: check-install.sh <repo>
# Installs <publisher>.<name> from the Marketplace and reads the VS Code
# logs. Prints {"installed":bool,"activation":"ok"|"error"|"not opened",
# "duplicate":bool,"others":[ids]}.
set -eu
pkg="$1/package.json"
id="$(jq -r .publisher "$pkg").$(jq -r .name "$pkg")"
ext_dir=${VSCODE_EXTENSIONS:-$HOME/.vscode/extensions}
logs=${VSCODE_LOGS:-"$HOME/Library/Application Support/Code/logs"}

installed=false
if [ -z "${SKIP_INSTALL:-}" ]; then
  for _ in 1 2 3 4 5 6; do
    code --install-extension "$id" >/dev/null 2>&1 || true
    if code --list-extensions | grep -qix "$id"; then installed=true; break; fi
    sleep 30
  done
fi

# Another installed extension with one of our commands, such as an old
# local build, makes our activate() fail with "command ... already exists".
ours=$(jq -c '[.contributes.commands[]?.command]' "$pkg")
# extensions.json lists only installed extensions; an uninstalled folder
# stays on disk until VS Code restarts.
others=$(jq -r '.[].relativeLocation' "$ext_dir/extensions.json" 2>/dev/null | while read -r dir; do
  f="$ext_dir/$dir/package.json"
  [ -f "$f" ] || continue
  jq -r --argjson ours "$ours" --arg id "$id" '
    "\(.publisher).\(.name)" as $x
    | [.contributes.commands[]?.command] as $c
    | select(($x | ascii_downcase) != ($id | ascii_downcase))
    | select(($c - $ours | length) < ($c | length))
    | $x' "$f" 2>/dev/null
done | sort -u | jq -R . | jq -sc .)

# Each VS Code start makes a new log folder; read them all, so a restart
# does not hide the last result. Lines start with a timestamp, so sort works.
last=$(cat "$logs"/*/window*/exthost/exthost.log 2>/dev/null |
  grep -E "_doActivateExtension $id,|Activating extension $id failed" | sort | tail -1 || true)
case "$last" in
  *failed*) activation=error ;;
  "") activation="not opened" ;;
  *) activation=ok ;;
esac

jq -nc --argjson i "$installed" --arg a "$activation" --argjson o "$others" \
  '{installed:$i,activation:$a,duplicate:($o|length>0),others:$o}'
