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

Pushes to `main` publish the Template to GHCR. After the first publication, set the `devcontainer-templates/ai-tools` package visibility to public in GitHub package settings.

This personal collection is consumed directly by its OCI reference and is not registered in the public containers.dev Template index.
