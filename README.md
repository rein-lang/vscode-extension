# vscode-extension

A [Rein](https://rein-lang.com) program that ships a VS Code extension. It does not write extension code. It takes an extension that works and gets it to users.

## What it does

Each run reads the repo and the Marketplace, then does the first missing step:

1. **Name** – the `name` and `displayName` must be free. Marketplace names are unique across all publishers.
2. **Publisher** – the user signs in; the program creates the publisher or uses one the user owns.
3. **Icon** – a 256 px `images/icon.png` from the project logo. No logo? It hands off to `logo-creation`.
4. **README** – the Install section leads with the Marketplace link.
5. **Workflow** – `.github/workflows/publish.yml` publishes when a `v*` tag is pushed. It uses Marketplace trusted publishing, so the repo stores no token.
6. **Release** – after the user approves, it creates the trusted publishing policy, pushes the version tag, and waits for the publish.
7. **Install check** – installs the extension from the Marketplace and reads the VS Code log to check that it starts. It finds an old local copy that has the same commands.

Each code change goes out as one pull request, handed to `pr-handling`. Run the program again after each step.

Steps that change accounts or go public ask the user first: creating a publisher, the trust policy, and the release.

## Run

```sh
rein install -g github:rein-lang/vscode-extension
rein step --flow vscode-extension --answer repo=/path/to/your-extension --json
```

It needs `gh`, `jq`, `curl`, `git`, `code`, and `rsvg-convert` for the icon.

## Next release

Bump `version` in `package.json` with a pull request, then run the program. It pushes the tag, and the workflow publishes the new version.

## Develop

```sh
rein check .
scripts/test.sh
```

The `.githooks/pre-push` hook runs both before each push.
