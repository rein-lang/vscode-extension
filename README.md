# vscode-extension

A [Rein](https://rein-lang.com) program that ships a VS Code extension. It does not write extension code. It takes an extension that works and gets it to users.

## What it does

Each run reads the repo and the Marketplace, then does the first missing step:

1. **Name** – the `name` and `displayName` must be free. Marketplace names are unique across all publishers.
2. **Publisher** – the user signs in; the program creates the publisher or uses one the user owns.
3. **Icon** – a 256 px `images/icon.png` from the project logo. No logo? It hands off to `logo-creation`.
4. **README** – the Install section leads with the Marketplace link.
5. **Workflow** – `.github/workflows/publish.yml` publishes on each merge to `main` when the Marketplace lacks the `package.json` version, then tags it. It uses Marketplace trusted publishing, so the repo stores no token.
6. **Release** – after the user approves, it creates the trusted publishing policy. The merge of a version bump publishes; the program waits for that run. It never pushes a tag or publishes by hand.
7. **Install check** – installs the extension from the Marketplace and reads the VS Code log to check that it starts. It finds an old local copy that has the same commands.

Each code change goes out as one pull request, handed to `pr-handling`. Run the program again after each step.

Steps that change accounts ask the user first: creating a publisher and the trust policy. A release goes public only through a merged pull request.

## Run

```sh
rein install -g github:rein-lang/vscode-extension
rein step --flow vscode-extension --answer repo=/path/to/your-extension --json
```

It needs `gh`, `jq`, `curl`, `git`, `code`, and `rsvg-convert` for the icon.

## Next release

Bump `version` in `package.json` with a pull request and merge it. The workflow publishes the new version and tags it. Run the program to watch the run and check the install.

## Develop

```sh
rein check .
scripts/test.sh
```

The `.githooks/pre-push` hook runs both before each push.
