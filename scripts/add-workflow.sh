#!/bin/sh
# Usage: add-workflow.sh <repo>
# Writes .github/workflows/publish.yml: a v* tag runs the tests, checks the
# tag matches package.json, and publishes with Marketplace trusted
# publishing (GitHub OIDC). Also keeps .github/ out of the vsix.
set -eu
repo=$1
mkdir -p "$repo/.github/workflows"
if [ -f "$repo/pnpm-lock.yaml" ]; then
  setup='      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm run --if-present test'
else
  setup='      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm test --if-present'
fi
cat > "$repo/.github/workflows/publish.yml" <<YML
# Publishes the extension to the VS Code Marketplace when a v* tag is pushed.
# Auth is Marketplace trusted publishing (GitHub OIDC), so no token is stored.
name: Publish

on:
  push:
    tags: ["v*"]

permissions:
  contents: read
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
$setup
      - name: Check tag matches package.json version
        run: test "v\$(node -p 'require("./package.json").version')" = "\$GITHUB_REF_NAME"
      - run: npx --yes @vscode/vsce publish --oidc --skip-duplicate
YML
touch "$repo/.vscodeignore"
grep -qx '.github/' "$repo/.vscodeignore" || echo '.github/' >> "$repo/.vscodeignore"
echo "$repo/.github/workflows/publish.yml"
