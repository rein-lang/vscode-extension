#!/bin/sh
# Offline self-test for the scripts that touch only local files.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir "$tmp/empty"
"$here/read-state.sh" "$tmp/empty" | grep -q '"manifest":false'

mkdir "$tmp/ext"
touch "$tmp/ext/pnpm-lock.yaml"
"$here/add-workflow.sh" "$tmp/ext" > /dev/null
"$here/add-workflow.sh" "$tmp/ext" > /dev/null
grep -q -- '--oidc' "$tmp/ext/.github/workflows/publish.yml"
grep -q 'pnpm install' "$tmp/ext/.github/workflows/publish.yml"
grep -q 'branches: \[main\]' "$tmp/ext/.github/workflows/publish.yml"
grep -q -- '--skip-duplicate' "$tmp/ext/.github/workflows/publish.yml"
grep -q 'submodules: recursive' "$tmp/ext/.github/workflows/publish.yml"
test "$(grep -cx '.github/' "$tmp/ext/.vscodeignore")" = 1

echo '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" fill="#0d9488"/></svg>' > "$tmp/logo.svg"
"$here/make-icon.sh" "$tmp/logo.svg" "$tmp/ext" > /dev/null
test -s "$tmp/ext/images/icon.png"
test -s "$tmp/ext/images/logo.png"

mkdir -p "$tmp/exts/old" "$tmp/exts/other" "$tmp/logs/1/window1/exthost"
echo '{"publisher":"me","name":"ext","contributes":{"commands":[{"command":"ext.restart"}]}}' > "$tmp/ext/package.json"
echo '{"publisher":"me","name":"ext-old","contributes":{"commands":[{"command":"ext.restart"}]}}' > "$tmp/exts/old/package.json"
echo '{"publisher":"x","name":"y","contributes":{"commands":[{"command":"y.go"}]}}' > "$tmp/exts/other/package.json"
mkdir -p "$tmp/exts/gone"
echo '{"publisher":"me","name":"ext-gone","contributes":{"commands":[{"command":"ext.restart"}]}}' > "$tmp/exts/gone/package.json"
echo '[{"relativeLocation":"old"},{"relativeLocation":"other"}]' > "$tmp/exts/extensions.json"
echo '2026-01-01 10:00:00.000 [error] Activating extension me.ext failed due to an error:' > "$tmp/logs/1/window1/exthost/exthost.log"
out=$(SKIP_INSTALL=1 VSCODE_EXTENSIONS="$tmp/exts" VSCODE_LOGS="$tmp/logs" "$here/check-install.sh" "$tmp/ext")
echo "$out" | grep -q '"activation":"error"'
echo "$out" | grep -q '"others":\["me.ext-old"\]'
echo '2026-01-01 10:01:00.000 [info] ExtensionService#_doActivateExtension me.ext, startup: false' >> "$tmp/logs/1/window1/exthost/exthost.log"
mkdir -p "$tmp/logs/2/window1/exthost"
echo '2026-01-02 09:00:00.000 [info] ExtensionService#_doActivateExtension other.ext, startup: false' > "$tmp/logs/2/window1/exthost/exthost.log"
SKIP_INSTALL=1 VSCODE_EXTENSIONS="$tmp/exts" VSCODE_LOGS="$tmp/logs" "$here/check-install.sh" "$tmp/ext" | grep -q '"activation":"ok"'
echo "scripts ok"
