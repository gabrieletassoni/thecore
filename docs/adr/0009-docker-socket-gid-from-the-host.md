# Give the devcontainer user the host's Docker socket group

The devcontainer bind-mounts the host's `/var/run/docker.sock`, which keeps the host's group id (973 on the host where this was found, on 2026-11-19). `vscode` is in the image's `docker` group, whose id is fixed when the image is built (996 in `vscode-devcontainers-thecore:3`), so on most hosts every `docker` command failed with `permission denied while trying to connect to the docker API` and worked only through `sudo`.

**Decision**: `samples/devcontainer/docker-socket-gid.sh`, run last by `devcontainer.json`'s `initializeCommand`, on the host. It writes `DOCKER_SOCKET_GID=<the socket's gid>` to `.devcontainer/.env`, and `docker-compose.yml` adds it to the app container with `group_add: ["${DOCKER_SOCKET_GID:-996}"]`. Without `.env` compose falls back to 996, the previous behaviour. `samples/devcontainer/.gitignore` keeps `.env` out of git: it differs on every host, and Rails' own `.gitignore` only ignores `/.env*` at the root.

The script is the same file, byte for byte, as `thecore_devcontainer`'s canonical `.devcontainer/docker-socket-gid.sh` (its ADR 0006 records the options considered: `groupmod` at start, `chmod 666`, baking the gid into the image), tested there by `test/docker-socket-gid.sh`. Like `heal-stale-containers.sh` (ADR 0008), it is also in `thecore_code_extension`'s `templates/setupDevContainer/` and in the files `thecore_generators`' App template fetches from here. Edit it in `thecore_devcontainer` and copy it everywhere.

## Consequences

- `group_add` is applied when the container is created: after Docker is reinstalled on the host with a different gid, the container must be rebuilt.
- The App template now fetches ten `.devcontainer/*` files instead of eight.
