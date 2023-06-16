[[_TOC_]]

# TL;DR

1. Be sure to have [docker](https://www.docker.com/) installed, have a look at the [preferred](98_SETUP_DOCKER_IN_WSL.md) way in windows (Without Docker Desktop which slows down all the experience).
1. Open [Visual Studio Code](https://code.visualstudio.com/)
2. Be sure to have these two extensionsinstalled in VS Code: [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) and [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. Download the [devcontainer sample config](../samples/devcontainer/)
4. Put it in the root of your project.
5. Extract it.
6. Rename the `devcontainer` folder to `.devcontainer` (just add a dot before the name).
6. Optionally change the **name** of the Dev Container in [devcontainer.json](../samples/devcontainer/devcontainer.json)
7. Open the root folder of your project (the one containing the `.devcontainer` folder) with VS Code.
8. A popup will show asking to **Reopen in container**, please do it.
9. Done, you are projected into the container and have a complete thecore 3 environment set up without effort.

# Forewords

Why Visual Studio Code? It's free, it's poweful, it's extensible, it's Agile.
Why Develop into a container? Because it's self contained and isolates your dev environment from your main computer thus avoiding any conflict and incompatibility. It enabes you to experiment inside a sandboxed environment already setup for you for the best experience. Moreover, it enables effective portability of the development experience for your project (any developer will experience the same) and can simulate a closer version of the deployed releases and CI/CD pipeline environments.
