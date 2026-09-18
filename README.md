# Install Git, Docker & Kind on AWS EC2 Linux

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


---

## 6. Install Helm

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## 7. Add Prometheus Community Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## 8. Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

---

## 9. Install kube-prometheus-stack

```bash
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring
```

Verify installation:

```bash
kubectl get pods -n monitoring
```

Wait until all monitoring pods are in the `Running` state.

---

## 10. Access Monitoring Applications by port forwarding

### Prometheus

```bash
nohup kubectl port-forward \
  -n monitoring \
  svc/monitoring-kube-prometheus-prometheus \
  9090:9090 \
  --address=0.0.0.0 \
  > prometheus-port-forward.log 2>&1 &
```

```text
http://<EC2-PUBLIC-IP>:9090
```

---

### Alertmanager

```bash
nohup kubectl port-forward \
  -n monitoring \
  svc/monitoring-kube-prometheus-alertmanager \
  9093:9093 \
  --address=0.0.0.0 \
  > alertmanager-port-forward.log 2>&1 &
```


```text
http://<EC2-PUBLIC-IP>:9093
```

---

### Grafana

```bash
nohup kubectl port-forward \
  -n monitoring \
  svc/monitoring-grafana \
  3001:80 \
  --address=0.0.0.0 \
  > grafana-port-forward.log 2>&1 &
```

```text
http://<EC2-PUBLIC-IP>:3001
```

---

## 11. Retrieve Grafana Username and Password

```bash
echo "Username:"
kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-user}" | base64 --decode
echo

echo "Password:"
kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo
```

---

## 12. Validate Monitoring Stack

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

Ensure:

- Prometheus is accessible on port `9090`
- Alertmanager is accessible on port `9093`
- Grafana is accessible on port `3001`
- All monitoring pods are in `Running` state

---

**Happy Coding!** 🚀
```