# Install Git, Docker & Kind on AWS EC2 Linux

Complete guide to install **Git**, **Docker**, and **Kind** (Kubernetes in Docker) on an AWS EC2 Linux instance.

**Supported AMIs:**
- Amazon Linux 2
- Amazon Linux 2023
- Ubuntu 20.04 / 22.04 / 24.04

---

## Prerequisites

- Running EC2 instance
- SSH access
- Outbound internet access

### Connect to the instance

```bash
# Amazon Linux
ssh -i your-key.pem ec2-user@<EC2-PUBLIC-IP>

# Ubuntu
ssh -i your-key.pem ubuntu@<EC2-PUBLIC-IP>
```

---

## 1. Update the System

### Amazon Linux
```bash
sudo yum update -y
# or on Amazon Linux 2023
sudo dnf update -y
```

### Ubuntu
```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Install Git

### Amazon Linux
```bash
sudo yum install -y git
# or
sudo dnf install -y git
```

### Ubuntu
```bash
sudo apt install -y git
```

**Verify:**
```bash
git --version
```

---

## 3. Install Docker

### Amazon Linux 2 / Amazon Linux 2023

```bash
# Install Docker
sudo yum install -y docker
# or on AL2023
sudo dnf install -y docker

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

> **Important:** Log out and log back in (or run `newgrp docker`) for the group change to take effect.

### Ubuntu (Official Method)

```bash
# Install prerequisites
sudo apt install -y ca-certificates curl

# Add Docker’s official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
```

**Verify Docker:**
```bash
docker --version
docker run hello-world
```

---

## 4. Install Kind

```bash
# Download Kind binary (AMD64)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64

# For ARM64 (Graviton instances)
# curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-arm64

# Make executable and move to PATH
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

**Verify:**
```bash
kind version
```

---

## 5. Install kubectl (Recommended)

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Verify:**
```bash
kubectl version --client
```

---

## Quick Verification

```bash
git --version
docker --version
docker ps
kind version
kubectl version --client
```

---

## Create a Kind Cluster

### Simple cluster
```bash
kind create cluster
```

### Multi-node cluster

Create a config file:

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
```

Then create the cluster:
```bash
kind create cluster --config kind-config.yaml
```

### Useful Kind commands
```bash
kind get clusters          # List clusters
kind delete cluster        # Delete default cluster
kind delete cluster --name <name>
```

---

## Notes

- After adding the user to the `docker` group, you **must** log out and log back in.
- Kind requires Docker to be running.
- Recommended instance type for Kind: **t3.medium** or larger.
- Ensure the EC2 instance has outbound internet access.

---

## Useful Commands Summary

| Tool     | Command                        | Description                     |
|----------|--------------------------------|---------------------------------|
| Git      | `git --version`                | Check Git version               |
| Docker   | `docker ps`                    | List running containers         |
| Docker   | `docker run hello-world`       | Test Docker installation        |
| Kind     | `kind create cluster`          | Create a local Kubernetes cluster |
| Kind     | `kind get clusters`            | List Kind clusters              |
| Kind     | `kind delete cluster`          | Delete the default cluster      |
| kubectl  | `kubectl get nodes`            | List nodes in the cluster       |

---

**Happy Coding!** 🚀
```