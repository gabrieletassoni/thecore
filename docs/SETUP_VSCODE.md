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

Once Docker and VS Code are running, install the Thecore extension (see below) and then continue with [WALKTHROUGH.md](WALKTHROUGH.md) Step 1 to set up the Thecore devcontainer for your project.

---

## Installing the Thecore VS Code extension

The Thecore extension is published automatically to **[open-vsx.org](https://open-vsx.org/extension/gabrieletassoni/thecore)** on every release. The Microsoft Marketplace is not recommended because it may not carry the latest version.

There are three ways to install it.

---

### Option 1 — Install from the command line using `ovsx` (recommended)

`ovsx` is the official open-vsx CLI. It downloads the extension directly from open-vsx.org and hands it to VS Code in one step.

```bash
# Node.js must be available (it is already present inside the Thecore devcontainer)
npx ovsx get gabrieletassoni.thecore -o /tmp/thecore.vsix
code --install-extension /tmp/thecore.vsix
```

You can also run this from inside the devcontainer terminal to refresh the extension after a new release.

---

### Option 2 — Download the `.vsix` manually and install from the Extensions panel

1. Go to the [GitHub Releases page](https://github.com/gabrieletassoni/vscode-thecore/releases) (or to [open-vsx.org](https://open-vsx.org/extension/gabrieletassoni/thecore) and click **Download**).
2. Download the `.vsix` file.
3. In VS Code open the Extensions panel (`Ctrl+Shift+X` / `Cmd+Shift+X`).
4. Click the `…` menu (top-right of the panel) → **Install from VSIX…** → select the downloaded file.

---

### Option 3 — Configure open-vsx as the Extensions panel marketplace (advanced)

This makes `gabrieletassoni.thecore` searchable directly in the VS Code Extensions panel. It works by pointing VS Code at the open-vsx gallery instead of the Microsoft Marketplace.

> **Caveats:** this replaces the Microsoft Marketplace entirely — extensions published only on Microsoft's marketplace will no longer appear. The setting is stored inside VS Code's application files and is reset on every VS Code update, so you will need to redo it after upgrading.

**Find `product.json` for your platform:**

| Platform | Path |
|---|---|
| Linux | `/usr/share/code/resources/app/product.json` |
| macOS | `/Applications/Visual Studio Code.app/Contents/Resources/app/product.json` |
| Windows | `C:\Program Files\Microsoft VS Code\resources\app\product.json` |

Open the file in a text editor with write permission (you may need `sudo` on Linux/macOS). Find the `extensionsGallery` key and replace its value — or add the key if absent — with:

```json
"extensionsGallery": {
  "serviceUrl": "https://open-vsx.org/vscode/gallery",
  "itemUrl": "https://open-vsx.org/vscode/item",
  "resourceUrlTemplate": "https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}"
}
```

Save the file and restart VS Code. You can now search `gabrieletassoni.thecore` in the Extensions panel and install it like any other extension.

To restore the Microsoft Marketplace, revert the `extensionsGallery` block to its original value (or reinstall VS Code).
