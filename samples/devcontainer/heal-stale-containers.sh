#!/bin/bash
# Run on the HOST by devcontainer.json's initializeCommand, before VS Code
# starts the compose project. Usage: heal-stale-containers.sh <workspace folder>
#
# VS Code starts a compose devcontainer with `docker compose up --no-recreate`,
# so it restarts the containers already there instead of creating new ones.
# A stopped container keeps the id of the network it was attached to. If that
# network is gone (a `docker network prune`, a daemon upgrade or reset of its
# network store), compose creates a new one with the same name, but the old
# containers still point at the old id, and the start fails with
#   failed to set up container networking: network <id> not found
# and keeps failing on every reopen and every reboot.
#
# This removes the project's containers when one of them points at a network
# that no longer exists, so compose recreates them. Volumes are never removed:
# databases and caches survive. Anything else is left alone.
#
# No `-e`, and always exit 0: a failure here must never stop VS Code from
# opening the folder; compose then reports whatever is really wrong.
# Tested by thecore_devcontainer's test/heal-stale-containers.sh. Every copy
# of this file is identical: change it there, then copy it everywhere.

folder="${1:-$PWD}"

# The primary container carries VS Code's devcontainer.local_folder label;
# its compose project label names every container of the project.
projects=$(docker ps -a --filter "label=devcontainer.local_folder=$folder" \
  --format '{{.Label "com.docker.compose.project"}}' 2>/dev/null | sort -u)

for project in $projects; do
  ids=$(docker ps -aq --filter "label=com.docker.compose.project=$project")
  stale=no
  for id in $ids; do
    for network in $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}} {{end}}' "$id"); do
      docker network inspect "$network" >/dev/null 2>&1 || stale=yes
    done
  done
  [ "$stale" = yes ] || continue
  echo "heal-stale-containers: removing the containers of $project, their network no longer exists (volumes are kept)"
  docker rm $ids >/dev/null
done
exit 0
