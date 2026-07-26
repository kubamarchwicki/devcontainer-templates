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
