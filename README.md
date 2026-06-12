# DevOps-Project-012: From Scratch to Production — Deploying EKS Clusters & Applications with CI/CD using Jenkins and Terraform

![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20EKS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-1.15.6-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-25.0.14-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-v3.21.0-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![eksctl](https://img.shields.io/badge/eksctl-0.227.0-FF9900?style=for-the-badge&logo=amazoneks&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-Security%20Scan-1904DA?style=for-the-badge&logo=aquasecurity&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-LoadBalancer-009639?style=for-the-badge&logo=nginx&logoColor=white)

This project provisions a Jenkins CI/CD server using Terraform, then uses a Jenkins pipeline to provision an Amazon EKS cluster (also via Terraform) and deploy an Nginx application exposed through a LoadBalancer service.

## 🏗️ Architecture

```
Manual: terraform apply (tf-aws-ec2)
    ↓
Jenkins-Server EC2 created (with Jenkins, Docker, Terraform,
AWS CLI, kubectl, eksctl, Helm, Trivy)
    ↓
Jenkins Pipeline (parameterized: action = apply/destroy)
    ↓
Checkout → Terraform Init/Validate/Plan (tf-aws-eks)
    ↓
Manual Approval (input step)
    ↓
Terraform apply/destroy -auto-approve → EKS Cluster + Node Group
    ↓
aws eks update-kubeconfig
    ↓
kubectl apply → Nginx Deployment + LoadBalancer Service
```

## 🖥️ Infrastructure

| Resource | Type | Purpose |
|---|---|---|
| Jenkins-Server | EC2 t2.medium (Amazon Linux 2023) | Jenkins, Docker, Terraform, AWS CLI, kubectl, eksctl, Helm, Trivy |
| EKS Cluster | Managed (Kubernetes 1.31) | Runs Nginx application |
| EKS Node Group | t2.small SPOT (min 1, desired 2, max 3) | Worker nodes |
| S3 Bucket | `terraform-eks-cicd-hmurafique` | Terraform remote state |

## 🛠️ Tools & Versions

- Terraform 1.15.6
- Jenkins (latest, Java 21 / Amazon Corretto 21)
- Docker 25.0.14
- AWS CLI v2.35.3
- kubectl v1.36.1
- eksctl 0.227.0
- Helm v3.21.0
- Trivy 0.71.0

## 📂 Repository Structure

```
DevOps-Project-012/
├── tf-aws-ec2/
│   ├── backend.tf
│   ├── data.tf
│   ├── main.tf
│   └── variables.tf
├── scripts/
│   └── install_build_tools.sh
├── tf-aws-eks/
│   ├── backend.tf
│   ├── vpc.tf
│   ├── eks.tf
│   └── variables.tf
├── manifest/
│   ├── deployment.yaml
│   └── service.yaml
└── Jenkinsfile
```

## ⚙️ Setup Steps

### 1. Pre-requisites (manual, one-time)
- Create an S3 bucket for Terraform remote state (`terraform-eks-cicd-hmurafique`)
- Create an AWS Key Pair (`jenkins-server-keypair`)
- Have AWS IAM Access Key ID / Secret Access Key ready

### 2. Provision Jenkins Server (`tf-aws-ec2`)
Run manually from a temporary EC2 instance (or local machine) with Terraform + AWS CLI configured:

```bash
cd tf-aws-ec2
terraform init
terraform plan
terraform apply -auto-approve
```

This creates a VPC, subnet, internet gateway, route table, security group, and the Jenkins EC2 instance. The `user_data` script (`scripts/install_build_tools.sh`) installs Jenkins, Docker, Terraform, AWS CLI, kubectl, eksctl, Helm, and Trivy.

### 3. Jenkins Server Configuration
- SSH into the Jenkins server, retrieve `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
- Open `http://<JENKINS-IP>:8080`, install suggested plugins, create admin user
- Install additional plugins: Terraform, Pipeline: Stage View, AWS Credentials, Docker Pipeline, Kubernetes CLI, Eclipse Temurin Installer
- Add credentials:
  - **AWS Credentials** (ID: `aws-credentials`)
  - **GitHub Username/Password** (ID: `github-token`)

### 4. EKS Infrastructure as Code (`tf-aws-eks`)
Defines:
- A dedicated VPC with public subnets across 2 AZs
- IAM roles/policies for the EKS cluster and node group
- An EKS cluster (Kubernetes 1.31)
- A SPOT-instance managed node group (t2.small, 1–3 nodes, desired 2)

### 5. Application Manifests (`manifest/`)
- `deployment.yaml` — Nginx Deployment (2 replicas)
- `service.yaml` — LoadBalancer Service exposing port 80

### 6. Jenkins Pipeline (`Jenkinsfile`)
Parameterized pipeline (`action`: `apply` / `destroy`) that runs:
1. **Checkout** — pulls source from GitHub
2. **Terraform Init** — initializes `tf-aws-eks` with S3 backend
3. **Terraform Validate**
4. **Terraform Plan**
5. **Approval** — manual `input` step before applying changes
6. **Terraform Apply/Destroy** — provisions or tears down the EKS cluster
7. **Update Kubeconfig** — `aws eks update-kubeconfig` (apply only)
8. **Deploy Nginx App** — `kubectl apply -f manifest/` (apply only)

### 7. Jenkins Job Setup
- New Item → Pipeline → `eks-cicd-pipeline`
- Parameterized: Choice Parameter `action` with values `apply` / `destroy`
- Pipeline script from SCM → GitHub repo, branch `main`, script path `Jenkinsfile`
- Run **Build with Parameters** → approve the plan at the Approval stage

## 🚀 Verification

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-eks-cluster
kubectl get nodes
kubectl get pods
kubectl get svc nginx-service
```

Open the `EXTERNAL-IP` (ELB hostname) from `nginx-service` in a browser — the Nginx welcome page should load.

## 🔧 Issues Faced & Fixes

| Issue | Fix |
|---|---|
| Jenkins failed to start — "Running with Java 17, minimum required is Java 21" | Installed `java-21-amazon-corretto-devel` from the Amazon Corretto repo and switched default via `alternatives --config java` |
| `java-21-amazon-corretto` package not found / excluded by repo priority | Installed the `-devel` variant with `--disableexcludes=all` from the AmazonCorretto repo |
| `kubectl`, `eksctl`, `helm`, `trivy`: command not found after install | `/usr/local/bin` was not in `$PATH` — added it to `~/.bashrc` and `/etc/environment` |
| `kubectl get nodes` → 403 Forbidden / `system:anonymous` (when run manually as root/ec2-user) | Ran `aws eks update-kubeconfig` for that user; used full path `/usr/local/bin/kubectl` since `sudo` resets `secure_path` |
| Browsing the EKS API `cluster_endpoint` URL shows `403 Forbidden: system:anonymous` | Expected behavior — the EKS API server requires authenticated `kubectl`/IAM access, not a browser |

## 🧹 Cleanup

To avoid ongoing AWS charges:

### 1. Destroy the EKS cluster via Jenkins
Run the `eks-cicd-pipeline` job with **action = destroy**, approve at the Approval stage. This removes the EKS cluster, node group, and associated VPC resources via Terraform.

### 2. Destroy the Jenkins server infrastructure
From the Terraform-Runner instance:
```bash
cd tf-aws-ec2
terraform destroy -auto-approve
```

### 3. Terminate any temporary EC2 instances ⚠️ (critical)
AWS Console → EC2 → Instances → terminate `Terraform-Runner` (and `Jenkins-Server` if not destroyed via Terraform)

### 4. Empty and delete the S3 state bucket (optional)
AWS Console → S3 → `terraform-eks-cicd-hmurafique` → empty bucket → delete bucket

### 5. Delete unused Key Pairs and Security Groups (optional)
EC2 → Key Pairs / Security Groups → remove if no longer needed

### 6. GitHub Repository
Keep for reference, or delete if no longer needed.

> ⚠️ Running EC2 instances and an active EKS cluster (control plane + SPOT nodes + LoadBalancer/ELB) continue to incur AWS charges until terminated/destroyed.

## ✅ Result

A fully automated, parameterized CI/CD pipeline: Jenkins provisions its own infrastructure via Terraform, then a single pipeline run (with manual approval) provisions a production-grade EKS cluster and deploys a containerized Nginx application exposed via AWS LoadBalancer — with a one-click `destroy` option for teardown.
