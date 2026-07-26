# Codex and Claude Code

A personal Dev Container Template that installs the Codex and Claude Code CLIs.

It keeps each project's `/home/vscode/.codex` and `/home/vscode/.claude` directories in persistent Docker volumes. If `$HOME/workspaces/engineering-skills` exists on the host and contains an executable `scripts/link-skills.sh`, that checkout is mounted read-only and its linker runs after container creation. When the checkout is absent, skill linking is skipped.

Apply the published Template:

```sh
devcontainer templates apply \
    --workspace-folder . \
    --template-id ghcr.io/kubamarchwicki/devcontainer-templates/ai-tools:1
```

The Template is copied into the target repository. Existing projects do not automatically inherit later Template releases.
