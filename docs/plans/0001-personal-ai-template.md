# Personal AI Dev Container Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the starter examples with one reusable personal Dev Container Template that installs Codex and Claude Code, persists their home directories, and optionally links the private engineering-skills checkout.

**Architecture:** Publish one `ai-tools` Template from `src/ai-tools` through GHCR. The Template contains a small Ubuntu-based Dockerfile and a complete `.devcontainer/devcontainer.json`; Codex and Claude state live in project-scoped named volumes, while the host engineering-skills checkout is mounted read-only when present. The repository retains the starter smoke-test harness but narrows CI and documentation to this single Template, and publishing is deliberately documentation-PR-free.

**Tech Stack:** Dev Container Templates, Dev Container Features, Docker, GitHub Actions, GitHub Container Registry, Bash

## Global Constraints

- Use the Template id `ai-tools` and initial semantic version `1.0.0`.
- Publish under `ghcr.io/kubamarchwicki/devcontainer-templates/ai-tools`.
- Use `mcr.microsoft.com/devcontainers/base:ubuntu` as the Template base image.
- Install exactly `ghcr.io/anthropics/devcontainer-features/claude-code:1` and `ghcr.io/kubamarchwicki/devcontainer-features/codex:1`.
- Let those Features install Node.js themselves; use `overrideFeatureInstallOrder` to install Codex before Claude Code, without adding a separate Node Feature or Dockerfile package installation.
- Keep the container user `vscode`, `updateRemoteUserUID: true`, and `init: true`.
- Persist `/home/vscode/.codex` and `/home/vscode/.claude` in `${devcontainerId}`-scoped named volumes.
- Mount `${localEnv:HOME}/workspaces/engineering-skills` read-only at `/opt/engineering-skills`.
- The private engineering-skills repository must never be copied, cloned, vendored, or published by this repository.
- Make engineering-skills linking optional: create an empty host bind-source directory when absent and skip linking unless `scripts/link-skills.sh` is executable.
- Keep `DISABLE_AUTOUPDATER=1`.
- Replace the starter `hello` and `color` Templates; do not publish them.
- Publish on pushes to `main` and manual dispatch with only `contents: write` and `packages: write`.
- Do not generate documentation in the release job and do not create documentation pull requests.
- Use `actions/checkout@v4` and `devcontainers/action@v1`.
- Keep the collection personal: document direct CLI use, but do not register it in the public containers.dev index.

---

### Task 1: Replace the starter examples with the personal AI Template

**Files:**

- Delete: `src/color/`
- Delete: `src/hello/`
- Delete: `test/color/`
- Delete: `test/hello/`
- Create: `src/ai-tools/devcontainer-template.json`
- Create: `src/ai-tools/.devcontainer/devcontainer.json`
- Create: `src/ai-tools/.devcontainer/Dockerfile`
- Create: `src/ai-tools/README.md`
- Create: `test/ai-tools/test.sh`

**Interfaces:**

- Consumes: published Codex and Claude Code Features and an optional host checkout at `$HOME/workspaces/engineering-skills`
- Produces: a self-contained `ai-tools` Template and an end-to-end smoke test

- [ ] **Step 1: Confirm the personal Template is absent**

Run:

```sh
test -e src/ai-tools || test -e test/ai-tools
```

Expected: exit 1 because neither path exists in the untouched starter repository.

- [ ] **Step 2: Remove the starter example Templates**

Run:

```sh
git rm -r src/color src/hello test/color test/hello
```

Expected: the two example Templates and their tests are staged for deletion; `test/test-utils/test-utils.sh` remains.

- [ ] **Step 3: Add Template metadata**

Create `src/ai-tools/devcontainer-template.json`:

```json
{
    "id": "ai-tools",
    "version": "1.0.0",
    "name": "Codex and Claude Code",
    "description": "A personal development container with Codex, Claude Code, and optional shared engineering skills.",
    "documentationURL": "https://github.com/kubamarchwicki/devcontainer-templates/tree/main/src/ai-tools",
    "licenseURL": "https://github.com/kubamarchwicki/devcontainer-templates/blob/main/LICENSE",
    "platforms": [
        "Any"
    ]
}
```

- [ ] **Step 4: Add the base Dockerfile**

Create `src/ai-tools/.devcontainer/Dockerfile`:

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu
```

- [ ] **Step 5: Add the reusable Dev Container configuration**

Create `src/ai-tools/.devcontainer/devcontainer.json`:

```json
{
    "name": "AI Development",
    "build": {
        "dockerfile": "Dockerfile",
        "context": "."
    },
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1": {}
    },
    "overrideFeatureInstallOrder": [
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1"
    ],
    "initializeCommand": "mkdir -p \"${localEnv:HOME}/workspaces/engineering-skills\"",
    "remoteUser": "vscode",
    "updateRemoteUserUID": true,
    "init": true,
    "containerEnv": {
        "DISABLE_AUTOUPDATER": "1"
    },
    "mounts": [
        "source=${devcontainerId}-codex-home,target=/home/vscode/.codex,type=volume",
        "source=${devcontainerId}-claude-home,target=/home/vscode/.claude,type=volume",
        "source=${localEnv:HOME}/workspaces/engineering-skills,target=/opt/engineering-skills,type=bind,readonly"
    ],
    "onCreateCommand": "sudo chown -R vscode:vscode /home/vscode/.codex /home/vscode/.claude",
    "postCreateCommand": {
        "link-skills": "if [ -x /opt/engineering-skills/scripts/link-skills.sh ]; then /opt/engineering-skills/scripts/link-skills.sh; else echo 'engineering-skills checkout not found; skipping skill links'; fi"
    },
    "waitFor": "postCreateCommand"
}
```

The `initializeCommand` is intentionally retained only for the bind mount. Docker creates the two named volumes itself; creating Codex or Claude host-home directories would be unused.

- [ ] **Step 6: Add Template-specific documentation**

Create `src/ai-tools/README.md`:

```markdown
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
```

- [ ] **Step 7: Add the smoke test**

Create `test/ai-tools/test.sh`:

```bash
#!/bin/bash
cd "$(dirname "$0")"
source test-utils.sh

check "remote user" test "$(id -un)" = "vscode"
check "Codex CLI" codex --version
check "Claude Code CLI" claude --version
check "Codex home ownership" test "$(stat -c '%U:%G' /home/vscode/.codex)" = "vscode:vscode"
check "Claude home ownership" test "$(stat -c '%U:%G' /home/vscode/.claude)" = "vscode:vscode"
check "engineering-skills mount" test -d /opt/engineering-skills
check "Claude auto-updater disabled" test "${DISABLE_AUTOUPDATER}" = "1"

reportResults
```

Run:

```sh
chmod +x test/ai-tools/test.sh
```

- [ ] **Step 8: Validate Template structure and contracts**

Run:

```sh
jq -e '
    .id == "ai-tools" and
    .version == "1.0.0" and
    .name == "Codex and Claude Code" and
    .platforms == ["Any"] and
    (has("options") | not)
' src/ai-tools/devcontainer-template.json

jq -e '
    .name == "AI Development" and
    .build == {"dockerfile":"Dockerfile","context":"."} and
    (.features | keys) == [
        "ghcr.io/anthropics/devcontainer-features/claude-code:1",
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1"
    ] and
    .overrideFeatureInstallOrder == [
        "ghcr.io/kubamarchwicki/devcontainer-features/codex:1"
    ] and
    .remoteUser == "vscode" and
    .updateRemoteUserUID == true and
    .init == true and
    .containerEnv.DISABLE_AUTOUPDATER == "1" and
    (.mounts | length) == 3 and
    .waitFor == "postCreateCommand"
' src/ai-tools/.devcontainer/devcontainer.json

test "$(find src -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = "1"
test "$(find test -mindepth 1 -maxdepth 1 -type d ! -name test-utils | wc -l | tr -d ' ')" = "1"
test -x test/ai-tools/test.sh
```

Expected: both `jq` commands print `true`, all structural assertions exit zero, and only `ai-tools` remains as a publishable Template.

- [ ] **Step 9: Run the Template smoke test**

Run:

```sh
./.github/actions/smoke-test/build.sh ai-tools
./.github/actions/smoke-test/test.sh ai-tools
```

Expected:

- the Template builds on `mcr.microsoft.com/devcontainers/base:ubuntu`;
- Codex installs first and provides Node.js and npm before Claude Code installs;
- `codex --version` and `claude --version` pass;
- the test runs as `vscode`;
- both persistent home directories are owned by `vscode:vscode`;
- the empty optional engineering-skills mount does not fail creation;
- the test report ends with `All passed!`.

- [ ] **Step 10: Commit the Template**

Run:

```sh
git add src/ai-tools test/ai-tools
git diff --cached --check
git commit -m "feat: add personal AI dev container template"
```

Expected: one commit replacing only the sample Template content and tests with `ai-tools`.

---

### Task 2: Narrow CI, publishing, and repository documentation

**Files:**

- Modify: `.github/workflows/release.yaml`
- Modify: `.github/workflows/test-pr.yaml`
- Modify: `.github/actions/smoke-test/action.yaml`
- Modify: `README.md`
- Include: `docs/plans/0001-personal-ai-template.md`

**Interfaces:**

- Consumes: the `ai-tools` Template and smoke test from Task 1
- Produces: blocking pull-request smoke tests, publish-only GHCR releases, and direct personal-use instructions

- [ ] **Step 1: Confirm starter-only workflow behavior remains**

Run:

```sh
rg -n \
    'color:|hello:|actions/checkout@v3|generate-docs|Create PR for Documentation|pull-requests: write' \
    .github README.md
```

Expected: matches from the untouched starter workflows and documentation, proving that the repository has not yet been narrowed to `ai-tools`.

- [ ] **Step 2: Replace the pull-request test workflow**

Replace `.github/workflows/test-pr.yaml` with:

```yaml
name: "CI - Test Templates"
on:
  pull_request:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: "Smoke test ai-tools"
        uses: ./.github/actions/smoke-test
        with:
          template: "ai-tools"
```

The smoke test is intentionally blocking; do not add `continue-on-error`.

- [ ] **Step 3: Update the composite smoke-test action**

Replace `.github/actions/smoke-test/action.yaml` with:

```yaml
name: "Smoke test"
inputs:
  template:
    description: "Template to test"
    required: true

runs:
  using: "composite"
  steps:
    - name: "Checkout repository"
      uses: actions/checkout@v4

    - name: "Build template"
      shell: bash
      run: ${{ github.action_path }}/build.sh ${{ inputs.template }}

    - name: "Test template"
      shell: bash
      run: ${{ github.action_path }}/test.sh ${{ inputs.template }}
```

- [ ] **Step 4: Replace documentation-generating release automation**

Replace `.github/workflows/release.yaml` with:

```yaml
name: "Release Dev Container Templates"

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    if: ${{ github.ref == 'refs/heads/main' }}
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: "Publish Templates"
        uses: devcontainers/action@v1
        with:
          publish-templates: "true"
          base-path-to-templates: "./src"

        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 5: Replace the starter README**

Replace `README.md` with:

```markdown
# Personal Dev Container Templates

Personal Dev Container Templates published under `ghcr.io/kubamarchwicki/devcontainer-templates`.

## AI tools

`ai-tools` installs the Codex and Claude Code CLIs, persists their home directories in project-scoped Docker volumes, and optionally links skills from the private host checkout at `$HOME/workspaces/engineering-skills`.

Apply it to a project:

```sh
devcontainer templates apply \
    --workspace-folder . \
    --template-id ghcr.io/kubamarchwicki/devcontainer-templates/ai-tools:1
```

Then build or open the generated `.devcontainer` configuration.

## Local testing

```sh
./.github/actions/smoke-test/build.sh ai-tools
./.github/actions/smoke-test/test.sh ai-tools
```

## Publishing

Pushes to `main` publish the Template to GHCR. After the first publication, set the `devcontainer-templates/ai-tools` package visibility to public in GitHub package settings.

This personal collection is consumed directly by its OCI reference and is not registered in the public containers.dev Template index.
```

- [ ] **Step 6: Validate workflow syntax and contracts**

Run:

```sh
ruby -ryaml -e 'ARGV.each { |path| YAML.parse_file(path) }; puts "workflow yaml syntax ok"' \
    .github/workflows/release.yaml \
    .github/workflows/test-pr.yaml \
    .github/actions/smoke-test/action.yaml

ruby -ryaml -e '
    workflow=YAML.load_file(ARGV.fetch(0))
    deploy=workflow.fetch("jobs").fetch("deploy")
    abort "release permissions changed" unless deploy.fetch("permissions") == {
        "contents"=>"write",
        "packages"=>"write"
    }
    abort "unexpected release steps" unless deploy.fetch("steps").length == 2
    publish=deploy.fetch("steps").last
    abort "publish action changed" unless publish.fetch("uses") == "devcontainers/action@v1"
    abort "publish inputs changed" unless publish.fetch("with") == {
        "publish-templates"=>"true",
        "base-path-to-templates"=>"./src"
    }
    puts "release workflow contract ok"
' .github/workflows/release.yaml

ruby -ryaml -e '
    workflow=YAML.load_file(ARGV.fetch(0))
    jobs=workflow.fetch("jobs")
    abort "unexpected test jobs" unless jobs.keys == ["test"]
    job=jobs.fetch("test")
    abort "test must be blocking" if job.key?("continue-on-error")
    smoke=job.fetch("steps").last
    abort "wrong smoke action" unless smoke.fetch("uses") == "./.github/actions/smoke-test"
    abort "wrong Template" unless smoke.fetch("with") == {"template"=>"ai-tools"}
    puts "test workflow contract ok"
' .github/workflows/test-pr.yaml

if rg -n \
    'color:|hello:|actions/checkout@v3|generate-docs|Create PR for Documentation|pull-requests: write' \
    .github README.md; then
    exit 1
fi
```

Expected:

```text
workflow yaml syntax ok
release workflow contract ok
test workflow contract ok
```

The forbidden-pattern scan produces no output.

- [ ] **Step 7: Run fresh end-to-end verification**

Run:

```sh
./.github/actions/smoke-test/build.sh ai-tools
./.github/actions/smoke-test/test.sh ai-tools

git diff --check main...HEAD
git status --short
```

Expected: the complete smoke test passes, the diff has no whitespace errors, and status lists only the workflow, action, README, and plan changes for Task 2.

- [ ] **Step 8: Commit automation, documentation, and the plan**

Run:

```sh
git add \
    .github/workflows/release.yaml \
    .github/workflows/test-pr.yaml \
    .github/actions/smoke-test/action.yaml \
    README.md \
    docs/plans/0001-personal-ai-template.md

git diff --cached --check
git commit -m "ci: publish and test the personal template"
```

Expected: a clean worktree with two focused commits on the implementation branch.
