# Personal Dev Container Templates

Personal Dev Container Templates published under `ghcr.io/kubamarchwicki/devcontainer-templates`.

## AI tools

`ai-tools` installs the Codex and Claude Code CLIs, persists their home directories in project-scoped Docker volumes, and optionally links skills from the private host checkout at `$HOME/workspaces/engineering-skills`.

Apply it to a project:

```sh
devcontainer templates apply \
    --workspace-folder . \
    --template-id ghcr.io/kubamarchwicki/devcontainer-templates/ai-tools:1 \
    --template-args '{"projectName":"<PROJECT_NAME>"}'
```

`projectName` prefixes the persistent Codex and Claude volume names. Omit it to retain automatic `${devcontainerId}`-based project isolation.

Then build or open the generated `.devcontainer` configuration.

## Local testing

```sh
./.github/actions/smoke-test/build.sh ai-tools '{"projectName":"ai-tools-smoke"}'
./.github/actions/smoke-test/test.sh ai-tools
```

## Publishing

Pushes to `main` that change `src/**` automatically publish changed Templates to GHCR. The release workflow can also be run manually. You do not need to bump the version for ordinary template changes.

The `version` in each `devcontainer-template.json` is a baseline. Every subsequent commit on `main` that changes that template's directory adds one to its patch number. For example, a baseline of `1.1.3` produces `1.1.4` on the next template change, then `1.1.5`. A merge commit counts once; changes outside the template directory do not advance its version. A push containing several commits can advance the patch by more than one.

The workflow writes the calculated version into the package before publishing, without committing it back to `main`. To start a minor or major release, edit the baseline to a version higher than the latest published version, such as `1.2.0` or `2.0.0`. Published versions are recorded in Git tags such as `template_ai-tools_1.1.4`.

Rerunning a commit calculates the same version; already published releases are skipped. Releases run one at a time, and commits superseded by newer template changes are skipped so they cannot overwrite newer content. Later changes outside `src/**` do not cancel a pending release. Keep `main` history intact because version calculation depends on it.

Preview the versions locally (requires full Git history and current release tags):

```sh
python3 .github/scripts/prepare-release.py --dry-run
```

Run the release versioning tests:

```sh
python3 -B -m unittest discover -s test/release -v
```

After the first publication, set the `devcontainer-templates/ai-tools` package visibility to public in GitHub package settings.

This personal collection is consumed directly by its OCI reference and is not registered in the public containers.dev Template index.
