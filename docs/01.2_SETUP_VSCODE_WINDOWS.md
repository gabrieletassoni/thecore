# Setup: VS Code with DevContainers on Windows 11 (WSL, no Docker Desktop)

This guide sets up Visual Studio Code with DevContainers on Windows 11 using WSL (Windows Subsystem for Linux) with Docker running natively inside Ubuntu — **without Docker Desktop**. Running Docker inside WSL avoids the virtualisation overhead of Docker Desktop and typically gives faster container startup times and lower memory usage.

---

## Step 1: Install WSL and Ubuntu

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This installs WSL, downloads the latest Linux kernel, and sets Ubuntu as the default distribution. Restart when prompted.

> **Recommended:** ensure WSL version 2 is used and update to the latest WSL release:
> ```powershell
> wsl --update
> wsl -l -v   # VERSION column should show 2
> ```

---

## Step 2: Install Docker inside WSL (Ubuntu)

Open the **Ubuntu** terminal and run:

```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg

# Add Docker's GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable Docker to start automatically via systemd
# First, ensure systemd is enabled in WSL (edit /etc/wsl.conf):
#   [boot]
#   systemd=true
# Then restart WSL: wsl --shutdown (from PowerShell)
sudo systemctl enable docker
sudo service docker start

# Run Docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker ps
```

> **Enable systemd in WSL (required for `systemctl`):**
>
> ```bash
> sudo nano /etc/wsl.conf
> ```
> Add:
> ```ini
> [boot]
> systemd=true
> ```
> Then from PowerShell: `wsl --shutdown` and reopen Ubuntu.

---

## Step 3: Set up SSH keys for Git

```bash
sudo apt install openssh-client

# Start the SSH agent (add to ~/.bashrc to persist across sessions)
eval "$(ssh-agent -s)"
echo 'eval "$(ssh-agent -s)"' >> ~/.bashrc

# Generate a new key (skip if you already have one)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Accept defaults and do not set a passphrase (enables automated git operations)

# Add the key to the agent
ssh-add ~/.ssh/id_rsa

# Print the public key — paste it into GitHub / GitLab SSH settings
cat ~/.ssh/id_rsa.pub
```

---

## Step 4: Install Visual Studio Code on Windows and connect to WSL

1. Download and install VS Code from [code.visualstudio.com](https://code.visualstudio.com/Download).
2. Click the **Remote Development** icon (blue icon, bottom-left corner) → **Connect to WSL**.
3. VS Code installs the WSL component automatically and reopens connected to your Ubuntu environment.

---

## Step 5: Restart WSL and verify

Close VS Code, then from PowerShell:

```powershell
wsl --shutdown
```

Reopen VS Code — it will reconnect to WSL automatically. Verify the SSH agent is running:

```bash
ps aux | grep ssh-agent
echo $SSH_AUTH_SOCK
```

---

## Next step

Open your project folder in VS Code (from inside the WSL Ubuntu terminal: `code .`) and accept **Reopen in Container** when prompted.

Then follow [WALKTHROUGH.md](WALKTHROUGH.md) to create your Thecore application.
