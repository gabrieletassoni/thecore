#!/bin/bash
# Run on the HOST by devcontainer.json's initializeCommand, before VS Code
# starts the compose project. Usage: docker-socket-gid.sh [socket]
# (socket defaults to /var/run/docker.sock; the argument exists for the tests)
#
# The app container bind-mounts the host's /var/run/docker.sock, which keeps
# the host's group id (e.g. 973). The image's `docker` group has its own id
# (996), so `vscode` cannot use the socket and every docker command fails with
# "permission denied while trying to connect to the docker API".
#
# This writes the socket's gid to .devcontainer/.env, which compose reads, and
# docker-compose.yml adds it to the app container with
#   group_add:
#     - "${DOCKER_SOCKET_GID:-996}"
# The group is applied when the container is created: after the host's gid
# changes, rebuild the container.
#
# No `-e`, and always exit 0: a failure here must never stop VS Code from
# opening the folder; without .env compose falls back to 996.
# Tested by thecore_devcontainer's test/docker-socket-gid.sh. Every copy
# of this file is identical: change it there, then copy it everywhere.

socket="${1:-/var/run/docker.sock}"
env_file="$(dirname "$0")/.env"
gid=$(stat -L -c %g "$socket" 2>/dev/null)
[ -n "$gid" ] && echo "DOCKER_SOCKET_GID=$gid" > "$env_file"
exit 0
