# Setup: VS Code and Docker on Ubuntu 24.04

This guide installs Visual Studio Code and Docker on a fresh Ubuntu 24.04 system and configures SSH keys for Git, so you can open Thecore projects inside a DevContainer.

---

## Step 1: Install Visual Studio Code

```bash
sudo apt update
sudo apt install software-properties-common apt-transport-https curl
curl https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg
sudo add-apt-repository "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install code
```

Open VS Code:

```bash
code
```

Install the **Dev Containers** extension (`Ctrl+Shift+X` → search "Dev Containers").

---

## Step 2: Install Docker

```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo service docker start
```

Verify Docker works:

```bash
sudo docker run hello-world
```

Run Docker without `sudo` (log out and back in after this):

```bash
sudo usermod -aG docker $USER
```

---

## Step 3: Set up SSH keys for Git

```bash
sudo apt install openssh-client

# Generate a key (skip if you already have one)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Start the agent and add the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Print the public key — paste it into GitHub / GitLab SSH settings
cat ~/.ssh/id_rsa.pub
```

---

## Next step

Open your project folder in VS Code and accept **Reopen in Container** when prompted, or run:

```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

Then follow [WALKTHROUGH.md](WALKTHROUGH.md) to create your Thecore application.
