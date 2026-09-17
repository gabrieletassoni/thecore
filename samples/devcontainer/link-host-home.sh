#!/usr/bin/env bash
# Claude Code's plugin registry (~/.claude/plugins/known_marketplaces.json,
# installed_plugins.json) bakes in *absolute* host paths at install time
# (e.g. /home/<host-user>/.claude/plugins/...) instead of paths relative
# to $HOME. Inside this devcontainer the user is always `vscode`
# ($HOME=/home/vscode), so those recorded paths don't exist here even though
# the actual bind-mounted content does (under /home/vscode/.claude/...) —
# Claude Code reports every marketplace-installed plugin as
# "failed to load: cache-miss" as a result.
#
# Fix: alias the host developer's own home directory name to /home/vscode,
# so absolute paths baked in under the host's username transparently resolve
# to the real bind-mounted files. ${localEnv:USER} is substituted by VS Code
# from the HOST environment at container-create time, so this is portable
# across every developer's machine with no per-repo hardcoding.
#
# This script only warns on failure — it never fails the build.
set -uo pipefail

HOST_USER="${1:-}"

if [ -z "$HOST_USER" ] || [ "$HOST_USER" = "vscode" ]; then
  exit 0
fi

if [ -e "/home/$HOST_USER" ]; then
  # Already a symlink from a previous run, a real directory (unexpected),
  # or the container image now provisions this user for some other reason.
  # Never clobber it.
  exit 0
fi

if ! sudo ln -s /home/vscode "/home/$HOST_USER" 2>/dev/null; then
  echo "⚠️  Could not create /home/$HOST_USER -> /home/vscode symlink; Claude Code plugin paths baked in under your host username may fail to resolve."
fi
