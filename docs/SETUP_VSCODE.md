# DevContainers in Visual Studio Code

## What is a DevContainer?

A DevContainer is a containerised development environment defined in `.devcontainer/devcontainer.json`. When you open a project in VS Code, the container is built automatically and the full toolchain — Ruby, Rails, Node.js, database drivers, linters — is immediately available without any local installation.

## Why Thecore uses DevContainers

- **Consistency**: every developer uses the same binary versions of every tool. No "works on my machine" problems.
- **Clean host machine**: nothing is installed globally. Each project has its own isolated environment.
- **Fast onboarding**: clone the repository, open in VS Code, accept the "Reopen in Container" prompt — done.
- **Reproducibility**: the devcontainer image is version-controlled and rebuilt automatically, so the environment always matches the codebase.

## Platform setup

Follow the guide for your operating system to install Docker and VS Code before opening a Thecore devcontainer:

- [Linux (Ubuntu 24.04)](SETUP_VSCODE_LINUX.md)
- [Windows 11 via WSL — no Docker Desktop](SETUP_VSCODE_WINDOWS.md)
- [macOS](SETUP_VSCODE_MACOS.md)

Once Docker and VS Code are running, continue with [WALKTHROUGH.md](WALKTHROUGH.md) Step 1 to set up the Thecore devcontainer for your project.
