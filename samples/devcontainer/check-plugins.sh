#!/usr/bin/env bash
# Non-blocking check: this repo doesn't vendor Matt Pocock's Claude Code
# skills locally. It relies on the `mattpocock-skills` plugin being installed
# and enabled on the HOST machine; the devcontainer's existing `~/.claude`
# bind mount (see devcontainer.json `mounts`) then exposes the plugin's files
# here, and link-host-home.sh (run just before this script from
# `postCreateCommand`) makes the absolute paths Claude Code's own plugin
# registry recorded on the host resolve correctly too — together these
# require no further container-side configuration.
#
# This script only warns — it never fails the build.
set -uo pipefail

PLUGIN_KEY='mattpocock-skills@claude-plugins-official'
INSTALLED_FILE="$HOME/.claude/plugins/installed_plugins.json"
SETTINGS_FILE="$HOME/.claude/settings.json"

installed=false
enabled=false
grep -q "\"$PLUGIN_KEY\"" "$INSTALLED_FILE" 2>/dev/null && installed=true
grep -q "\"$PLUGIN_KEY\": true" "$SETTINGS_FILE" 2>/dev/null && enabled=true

if [ "$installed" != true ] || [ "$enabled" != true ]; then
  cat <<'EOF'

⚠️  Claude Code plugin "mattpocock-skills" isn't installed/enabled on your HOST machine.
   Skills like /ask-matt, /grill-with-docs, /tdd, /code-review won't be available in this
   container until you install it on the HOST (not inside the container):

     claude plugins install mattpocock-skills

   (official Claude Code marketplace, nothing else to add first — see
   https://github.com/mattpocock/skills)

EOF
fi

exit 0
