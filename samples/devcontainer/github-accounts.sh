#!/usr/bin/env bash
# A developer may forward several GitHub keys through the host's SSH agent, one per
# GitHub account (e.g. a work account and a personal one). GitHub accepts the first key
# the agent offers and identifies the user by it, so pushing to a repository owned by
# the other account is denied ("Permission ... denied to <first account>"). The host's
# own ~/.ssh/config, which tells them apart there, isn't in the container.
#
# Fix: ask GitHub which account each agent key belongs to, then make git use that key
# for remotes under that account (git@github.com:<account>/...), via
# includeIf "hasconfig:remote.*.url:...". Other remotes keep the agent's default. Nothing
# is hardcoded, so it works for every developer, and does nothing with a single key.
# Written to ~/.config/git/, since VS Code rewrites ~/.gitconfig and /etc/gitconfig on
# every container start. Only public keys are written: the private ones stay in the agent.
#
# This script only warns on failure — it never fails the build.
set -uo pipefail

KEYS_DIR="$HOME/.ssh/github-accounts"
GIT_CONFIG_DIR="$HOME/.config/git"
ACCOUNTS_CONFIG="$GIT_CONFIG_DIR/github-accounts"

keys=$(ssh-add -L 2>/dev/null) || exit 0

mkdir -p "$KEYS_DIR" "$GIT_CONFIG_DIR"
chmod 700 "$HOME/.ssh"
rm -f "$KEYS_DIR"/* "$ACCOUNTS_CONFIG"

github_account() {
  ssh -n -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=accept-new -i "$1" -T git@github.com 2>&1 \
    | sed -n 's/^Hi \([^!]*\)! You.*/\1/p'
}

found=0
while IFS= read -r key; do
  candidate=$(mktemp "$KEYS_DIR/key.XXXXXX")
  echo "$key" > "$candidate"
  account=$(github_account "$candidate")
  if [ -z "$account" ] || [ -e "$KEYS_DIR/$account.pub" ]; then
    rm -f "$candidate"
    continue
  fi
  mv "$candidate" "$KEYS_DIR/$account.pub"
  git config --file "$ACCOUNTS_CONFIG" \
    "includeIf.hasconfig:remote.*.url:git@github.com:$account/**.path" "$KEYS_DIR/$account.gitconfig"
  git config --file "$KEYS_DIR/$account.gitconfig" \
    core.sshCommand "ssh -o IdentitiesOnly=yes -i $KEYS_DIR/$account.pub"
  found=$((found + 1))
done <<< "$keys"

if [ "$found" -gt 0 ]; then
  git config --file "$GIT_CONFIG_DIR/config" --replace-all include.path "$ACCOUNTS_CONFIG" "$ACCOUNTS_CONFIG"
fi
