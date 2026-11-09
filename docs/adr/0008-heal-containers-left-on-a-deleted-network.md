# Remove devcontainer containers left on a deleted network before compose starts them

On 2026-11-09 the devcontainer stopped starting, on every reopen and after a reboot, with:

```
Error response from daemon: failed to set up container networking: network 46c637b0fe8b… not found
```

A stopped container keeps the id of the network it was attached to. The project's network `<project>_devcontainer_default` had been deleted while its containers were stopped (all user-defined networks on that host were gone after an unattended Docker upgrade; `docker network prune` does the same). On the next start `docker compose` created a new network with the same name, but VS Code starts a compose devcontainer with `docker compose up --no-recreate`, so compose restarted the old containers, which still pointed at the old id. Rebooting does not help: containers survive it.

**Decision**: `.devcontainer/heal-stale-containers.sh`, run by `devcontainer.json`'s `initializeCommand` (`bash .devcontainer/heal-stale-containers.sh '${localWorkspaceFolder}'`). VS Code runs `initializeCommand` on the host, before `docker compose up`. The script finds the project from the `devcontainer.local_folder` label VS Code puts on the primary container. If any container of that compose project points at a network that no longer exists, it removes the project's containers with a plain `docker rm`, and compose recreates them. Volumes are never removed, so the database and the bundle survive. A healthy project, a running project (`docker rm` without `-f` refuses it), another folder's project, and an unreachable Docker daemon are all left alone, and the script always exits 0, so it never prevents VS Code from opening the folder.

The script is the same file, byte for byte, in every Thecore app and in the three scaffolding sources: `thecore_code_extension`'s `templates/setupDevContainer/`, `thecore`'s `samples/devcontainer/` and the list of files `thecore_generators`'s `app_template.rb` fetches from it. `thecore_devcontainer/test/heal-stale-containers.sh` tests it against a real Docker daemon. Edit it there and copy it everywhere.

## Considered options

- **Do the cleanup in `docker-compose.yml`**: not possible. Compose has no hook that runs before it starts existing containers, and `--no-recreate` is VS Code's flag, not compose's.
- **`docker compose down` in `initializeCommand` on every open**: rejected. It also stops a container that is in use, for example when a second VS Code window opens the same folder.
- **`shutdownAction`**: VS Code only offers stopping the compose project on close, never removing it.
- **Remove the containers by hand when it happens**: what was done on 2026-11-09. It works, but the error does not say what to do, and it repeats after every Docker upgrade.

## Consequences

- After a network is deleted, the next open recreates the containers and runs `postCreateCommand` again (`bundle update` included), so that one start is slower.
- Anything stored in a container's writable layer and not in a volume is lost with the container. Nothing in these devcontainers keeps state there.
- The script relies on two labels: `devcontainer.local_folder` (VS Code's) and `com.docker.compose.project` (compose's). If a VS Code release renames the first one, the script silently does nothing and the original error comes back.
