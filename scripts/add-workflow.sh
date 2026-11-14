#!/bin/sh
# Usage: add-workflow.sh <repo>
# Writes .github/workflows/publish.yml: a merge to main runs the tests and
# publishes the package.json version when the Marketplace lacks it, then
# tags it. Auth is Marketplace trusted publishing (GitHub OIDC). Also keeps
# .github/ out of the vsix.
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
# A merge to main publishes the package.json version to the VS Code
# Marketplace when that version is not there yet, then tags it. A release
# is a merged version bump. Auth is Marketplace trusted publishing (GitHub
# OIDC), so no token is stored.
name: Publish

on:
  push:
    branches: [main]

concurrency: publish

permissions:
  contents: write
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
$setup
      - run: npx --yes @vscode/vsce publish --oidc --skip-duplicate
      - name: Tag the version
        run: |
          v="v\$(node -p 'require("./package.json").version')"
          git ls-remote --exit-code --tags origin "refs/tags/\$v" >/dev/null || {
            git tag "\$v"
            git push origin "\$v"
          }
YML
touch "$repo/.vscodeignore"
grep -qx '.github/' "$repo/.vscodeignore" || echo '.github/' >> "$repo/.vscodeignore"
echo "$repo/.github/workflows/publish.yml"
