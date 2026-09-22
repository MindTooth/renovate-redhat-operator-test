# Run the OpenShift release example

[`openshift-release.env`](openshift-release.env) pins an OpenShift release in
the `eus-4.22` channel. The regex manager in
[`.github/renovate.json`](.github/renovate.json) sends that version to
[`olm-catalog-datasource`](https://github.com/MindTooth/olm-catalog-datasource)'s
OpenShift update endpoint. The datasource returns graph-eligible releases and
per-release `changelogContent`. The changes in
[Renovate PR #45867](https://github.com/renovatebot/renovate/pull/45867)
include those notes in update PRs, including intermediate releases.

## Start the datasource

Follow the datasource's [getting-started guide](https://github.com/MindTooth/olm-catalog-datasource/blob/master/docs/GETTING_STARTED.md)
to build and start it on the same machine as Renovate, listening on port 8080.
The OpenShift release endpoint uses the official update graph; operator catalog
credentials are needed only if you also configure catalog sources. Verify the
endpoint before running Renovate:

```sh
curl --fail-with-body 'http://localhost:8080/v1/openshift-releases/eus-4.22/updates?currentVersion=4.21.21&arch=multi'
```

The response must contain a `releases` array with a newer, eligible version.
If there is no newer release, the graph has no update from the pinned version;
choose another installed version in `openshift-release.env` if needed.

To verify that Renovate includes the new `.env` file, run
`sh test/renovate-extraction.sh` from this repository. The test places the
current config and example in a temporary tracked Git repository, then checks
Renovate's extracted dependency. Renovate's local platform reads tracked files;
the test therefore works even before this new file is committed here.
For a direct run in this checkout, mark the file as intent to add with
`git add -N openshift-release.env`, then run
`LOG_LEVEL=debug renovate --platform local --dry-run=extract`.

## Run Renovate on your machine against GitHub

First commit and push this example and its Renovate config to the repository's
default branch. A GitHub platform run reads files from GitHub, not uncommitted
files in the current directory. Use a checkout of the **head of PR #45867**
(or a build containing that change), with its required Node.js and pnpm versions:

```sh
git clone --branch feat/custom-datasource-release-changelog-content https://github.com/MindTooth/renovate.git
cd renovate
pnpm install --frozen-lockfile
pnpm build
```

Set `RENOVATE_TOKEN` in your shell to a GitHub token with write access to this
repository's contents and pull requests. From the patched Renovate checkout,
run:

```sh
RENOVATE_PLATFORM=github node dist/renovate.js MindTooth/renovate-redhat-operator-test
```

The process runs locally, but `platform=github` makes it clone the GitHub
repository and push update branches and PRs there. Leave `RENOVATE_DRY_RUN`
unset for the PR-creating run. To preview without writes, add
`RENOVATE_DRY_RUN=full` to the command. `--platform=local` is useful for
checking extraction, but it cannot create branches or PRs.

The `localhost:8080` URL in the repository config is resolved on the machine
running Renovate. Run the datasource alongside Renovate on that machine; a
separate hosted Renovate instance cannot reach your laptop's localhost.
