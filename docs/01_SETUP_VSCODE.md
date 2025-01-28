[[_TOC_]]

# Using DevContainer in Visual Studio Code for Development

## Overview
In modern software development, managing consistent environments across different developers and machines is crucial. The DevContainer feature in Visual Studio Code (VS Code) helps address this by creating reproducible, isolated development environments that can be easily shared and configured using a simple configuration file (`devcontainer.json`). This setup offers significant advantages in terms of standardization, clean environments, and fast cold-starts, especially when onboarding new team members or replacing workstations.

## Why Use DevContainer in Visual Studio Code

A **DevContainer** is a containerized development environment, typically based on Docker, that allows you to define all the tools, libraries, and dependencies needed for your project in a configuration file. When a developer opens the project in VS Code, the DevContainer is automatically built (if not already present) and the environment is set up seamlessly. 

This approach offers a variety of benefits in terms of standardization, efficiency, and ease of setup:

---

## **Development Standardization Across Teams**

One of the main challenges in software development is ensuring all team members are working within the same development environment, regardless of their local operating systems or machine configurations. With DevContainers, you can define the environment for your project explicitly and share this definition among all team members.

### Key Benefits:
- **Consistency**: With a DevContainer, every developer is using the same environment. No more discrepancies in local dependencies, versions of software tools, or configurations. The project setup becomes entirely standardized.
- **Tooling Automation**: All the necessary tools (e.g., compilers, linters, debuggers) and dependencies (e.g., language libraries) are pre-configured. Developers don’t have to worry about version mismatches or missing components.
- **Cross-Platform Compatibility**: Whether your team members are using macOS, Linux, or Windows, the DevContainer ensures they all work in the same environment with the same configuration, avoiding the common "works on my machine" issues.
- **Ease of Onboarding**: New team members can get up to speed quickly by using the same DevContainer configuration, which reduces onboarding time and improves productivity.

---

## **Clean and Efficient Computer Setup**

Setting up a new computer or a clean environment can be a hassle, particularly when developers need to manually install and configure multiple tools and dependencies. A DevContainer simplifies this process by automating environment setup and ensuring a clean slate.

### Key Benefits:
- **No Need for Local Installations**: Developers don’t need to install tools or dependencies globally on their machine. Everything is contained within the DevContainer. This results in a cleaner system and fewer potential conflicts with other projects or system-wide tool installations.
- **Isolated Environment**: Each project can have its own environment with specific versions of dependencies, without interfering with other projects on the same machine.
- **Faster Setup**: Instead of manually installing dependencies and configuring tools, developers simply need to clone the project and open it in VS Code. The DevContainer will set up the environment automatically, saving time on the setup process.

---

## **Easy Cold Start for Computer Replacement or New Team Members**

When a developer's machine is replaced, or when new team members join the team, setting up their development environment can be time-consuming. However, with DevContainers, this process becomes streamlined and much faster.

### Key Benefits:
- **Quick Rebuild and Reuse**: If a developer's machine needs to be replaced, or if they work on multiple machines, they can quickly spin up a new DevContainer environment by simply pulling the project repository and opening it in VS Code. All dependencies and configurations are predefined, meaning they don’t need to go through a lengthy setup process.
- **No Dependency on Host Machine**: The configuration and setup of the development environment are entirely containerized, meaning there are no dependencies on the host machine's operating system or its configuration.
- **Zero Setup Time for New Team Members**: When onboarding a new developer, they simply need to install Docker and VS Code with the DevContainer extension, then open the project. The setup process becomes much faster compared to installing dependencies manually or setting up complex development environments.

---

## **Improved Collaboration and Knowledge Sharing**

Since DevContainers ensure that all developers are working within the same environment, it becomes easier to share knowledge, troubleshoot issues, and collaborate across teams. With a common environment, it's easier to understand the setup and configuration of the project, making knowledge transfer smoother.

### Key Benefits:
- **Shared Configuration**: Developers can share the `devcontainer.json` configuration file, ensuring that all collaborators are using the same development setup.
- **Unified Debugging**: With identical environments, debugging becomes simpler, as everyone can reproduce the same issue. There is no longer a need to track down specific local setups or configurations.
- **Less Configuration Drift**: With team members working in the same containerized environment, it's harder for configuration drift to occur (where individual developers' setups start to diverge over time).

---

## **Cost and Resource Efficiency**

DevContainers can improve resource usage and reduce the costs associated with managing development environments.

### Key Benefits:
- **Resource Isolation**: By using containers, you ensure that each project runs in its isolated environment. There’s no risk of resource conflicts between projects, and each container uses only the resources it needs.
- **Efficient Use of Docker**: Docker containers are lightweight compared to traditional virtual machines, meaning you can run multiple isolated development environments on the same host machine without consuming excessive resources.
- **Environment Reproducibility**: Because the DevContainer is defined in a configuration file, developers can easily recreate the exact same environment anywhere, reducing the time spent resolving environment-related issues.

---

## **Improved Developer Productivity**

By reducing setup times, ensuring a standardized environment, and eliminating configuration-related distractions, DevContainers help developers focus more on writing code and less on managing their environment.

### Key Benefits:
- **Instant Environment Setup**: Developers can quickly start working on any project with minimal setup required.
- **Reduced Context Switching**: With all dependencies encapsulated in the DevContainer, developers don’t have to worry about local configuration changes affecting other projects or tools.
- **Reproducibility of Build Environments**: Developers can confidently collaborate, knowing that the environment in which they are working is exactly the same for all team members.

## Walkthrough: Setting Up Visual Studio Code with DevContainers on a Windows 11 Computer Using WSL (No Docker Desktop)

This guide walks you through the steps of setting up Visual Studio Code (VS Code) with DevContainers on a Windows 11 system using the Windows Subsystem for Linux (WSL), without Docker Desktop. We'll install WSL with the latest Ubuntu, set up Docker inside WSL, configure SSH-agent for sharing SSH keys, generate SSH keys for GitLab/GitHub, and finally, create a Node.js DevContainer to test the environment.
From my experience, opting for Docker inside WSL rather than using Docker Desktop can offer a significant performance boost, especially in terms of speed and system resource efficiency. Docker Desktop adds a layer of complexity with its virtualization and interaction between Windows and Docker containers, which can introduce overhead. By using Docker directly within WSL, you eliminate this extra layer, allowing Docker to run natively in the Linux environment, which tends to be faster and more lightweight. This can lead to quicker container startup times, lower memory usage, and better overall performance for development tasks. While Docker Desktop has a lot of user-friendly features, if performance and direct control over the environment are key priorities, using WSL directly may be the more efficient choice. However, it's important to note that this experience can vary depending on specific use cases and system configurations.

### Step 1: Install WSL and Ubuntu on Windows 11

WSL allows you to run a Linux environment directly on Windows. Follow these steps to install WSL and set up Ubuntu.

1. **Enable WSL Feature on Windows:**
   - Open **PowerShell** as Administrator and run the following command:
     ```powershell
     wsl --install
     ```
     This will install WSL, download the latest Linux kernel, and set Ubuntu as your default distribution. If you’ve already installed WSL, you can upgrade by running:
     ```powershell
     wsl --update
     ```
   - Restart your computer when prompted.

2. **Install the Latest Ubuntu:**
   - Open the **Microsoft Store**, search for **Ubuntu**, and click **Install** for the latest Ubuntu version.
   - Once installed, open **Ubuntu** from the Start menu and follow the prompts to set up your Linux user account.

3. **Ensure WSL 2 is Installed:**
   - In **PowerShell** (as Administrator), verify that WSL 2 is installed by running:
     ```powershell
     wsl --list --verbose
     ```
     You should see your Ubuntu distribution set to **WSL 2**. If not, upgrade it using:
     ```powershell
     wsl --set-version Ubuntu-20.04 2
     ```

### Step 2: Install Docker in WSL (Without Docker Desktop)

To run Docker inside your WSL instance, you need to install Docker directly within Ubuntu.

1. **Install Docker Dependencies in WSL:**
   - Open the **Ubuntu** terminal (WSL) and update package lists:
     ```bash
     sudo apt update
     sudo apt install apt-transport-https ca-certificates curl software-properties-common
     ```
   
2. **Add Docker’s Official GPG Key and Repository:**
   - Download Docker's official GPG key:
     ```bash
     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/trusted.gpg.d/docker.asc
     ```
   - Add Docker's repository:
     ```bash
     sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
     ```

3. **Install Docker:**
   - Update package lists again and install Docker:
     ```bash
     sudo apt update
     sudo apt install docker-ce docker-ce-cli containerd.io
     ```

4. **Start Docker:**
   - Start the Docker service:
     ```bash
     sudo service docker start
     ```

5. **Enable Docker to Start on Boot:**
   - Enable Docker to start automatically:
     ```bash
     sudo systemctl enable docker
     ```

6. **Verify Docker Installation:**
   - Run the following to verify Docker is installed correctly:
     ```bash
     sudo docker --version
     sudo docker run hello-world
     ```
   This should download and run a test container to ensure Docker is working.

### Step 3: Install and Set Up SSH-Agent to Share SSH Keys with DevContainers

To work with Git repositories (like GitLab or GitHub) in your DevContainer, you need to ensure that your SSH keys are available inside the WSL environment.

1. **Install OpenSSH Client in Ubuntu (WSL):**
   - Install the OpenSSH client package if it's not already installed:
     ```bash
     sudo apt install openssh-client
     ```

2. **Start the SSH-Agent:**
   - Start the SSH agent to manage your keys:
     ```bash
     eval "$(ssh-agent -s)"
     ```

3. **Add Your SSH Key to the Agent:**
   - If you already have an SSH key, you can add it to the agent:
     ```bash
     ssh-add ~/.ssh/id_rsa
     ```
   - If you don’t have an SSH key, generate a new one.

4. **Generate an SSH Key (if you don’t have one yet):**
   - Run the following to generate a new SSH key (e.g., for GitHub or GitLab):
     ```bash
     ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
     ```
     Follow the prompts to specify the file location and passphrase.
   - After generating the key, add it to the SSH agent:
     ```bash
     ssh-add ~/.ssh/id_rsa
     ```

5. **Copy the SSH Key to GitLab/GitHub:**
   - Copy the SSH public key to your clipboard:
     ```bash
     cat ~/.ssh/id_rsa.pub
     ```
   - Log in to your GitHub or GitLab account, navigate to the SSH keys settings, and add your SSH public key.

### Step 4: Install Visual Studio Code on Windows

1. **Download Visual Studio Code:**
   - Go to the [VS Code download page](https://code.visualstudio.com/Download) and download the installer for Windows.

2. **Install VS Code:**
   - Run the installer and follow the installation instructions.

3. **Install the Remote - WSL Extension in VS Code:**
   - Open VS Code, navigate to the **Extensions** view (`Ctrl+Shift+X`), and search for **Remote - WSL**.
   - Click **Install** to install the extension.

### Step 5: Connect VS Code to WSL

1. **Open VS Code from WSL:**
   - Launch your Ubuntu terminal (WSL), and run:
     ```bash
     code .
     ```
   - This command will open the current directory in VS Code, but it will connect to the WSL environment.

2. **Verify WSL Connection:**
   - In VS Code, you should now see “WSL: Ubuntu” in the bottom-left corner of the window, confirming that you are connected to your Ubuntu distribution.

### Step 6: Create a Node.js DevContainer

Now, let’s create a Node.js DevContainer to ensure everything is working.

1. **Create a Project Folder:**
   - In the Ubuntu terminal, create a new directory for your project:
     ```bash
     mkdir my-node-devcontainer
     cd my-node-devcontainer
     ```

2. **Create a `devcontainer.json` File:**
   - In VS Code (connected to WSL), create a new file at `.devcontainer/devcontainer.json`:
     ```json
     {
       "name": "Node.js DevContainer",
       "image": "mcr.microsoft.com/vscode/devcontainers/javascript-node:latest",
       "features": {
         "git": "latest"
       }
     }
     ```

3. **Add a Simple Node.js App (Optional):**
   - Create a `server.js` file with the following content:
     ```javascript
     const http = require('http');

     const server = http.createServer((req, res) => {
       res.write('Hello from DevContainer!');
       res.end();
     });

     server.listen(3000, () => {
       console.log('Server running on http://localhost:3000');
     });
     ```

4. **Rebuild the DevContainer:**
   - Open the Command Palette (`Ctrl+Shift+P`) and search for **Remote-Containers: Reopen in Container**.
   - VS Code will rebuild and open the container using the configuration defined in `devcontainer.json`.

5. **Test the Setup:**
   - Once the DevContainer is built and running, open the integrated terminal inside VS Code (`Ctrl+``) and run the following to start your Node.js server:
     ```bash
     node server.js
     ```
   - Open your browser and go to [http://localhost:3000](http://localhost:3000). You should see "Hello from DevContainer!".


---

## Conclusion

DevContainers in Visual Studio Code provide a powerful way to ensure development standardization across teams, promote clean and efficient environments, and speed up the cold-start process for new machines or new team members. By automating environment setup, eliminating configuration drift, and simplifying onboarding, DevContainers significantly improve productivity and reduce friction in development workflows. The ability to share, replicate, and isolate environments means that teams can work faster, collaborate more effectively, and focus on the core aspects of their projects.


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
