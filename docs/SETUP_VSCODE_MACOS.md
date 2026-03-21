# Setup: VS Code with DevContainers on macOS

This guide installs Visual Studio Code and Docker Desktop on macOS and configures SSH keys for Git, so you can open Thecore projects inside a DevContainer.

---

## Step 1: Install Visual Studio Code

1. Download VS Code from [code.visualstudio.com](https://code.visualstudio.com/Download) — select the **macOS** `.dmg` file.
2. Open the `.dmg`, drag **Visual Studio Code** to **Applications**.
3. Launch VS Code from Applications or via Spotlight (`Cmd+Space` → "Visual Studio Code").
4. Install the **Dev Containers** extension (`Cmd+Shift+X` → search "Dev Containers").

---

## Step 2: Install Docker Desktop

1. Download **Docker Desktop for macOS** from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop).
2. Open the `.dmg` and drag **Docker** to Applications.
3. Launch Docker from Applications. Wait for the whale icon in the menu bar to show **Docker is running**.

Verify Docker works:

```bash
docker --version
docker run hello-world
```

---

## Step 3: Set up SSH keys for Git

macOS includes OpenSSH by default. If needed:

```bash
# Generate a key (skip if you already have one)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Start the agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Copy the public key to clipboard — paste it into GitHub / GitLab SSH settings
pbcopy < ~/.ssh/id_rsa.pub
```

---

## Next step

Open your project folder in VS Code and accept **Reopen in Container** when prompted, or run:

```
Cmd+Shift+P → Dev Containers: Reopen in Container
```

Then follow [WALKTHROUGH.md](WALKTHROUGH.md) to create your Thecore application.
