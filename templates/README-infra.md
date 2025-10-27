# Infrastructure

## Overview

This repository contains infrastructure-as-code (IaC) configurations for the project.

## Tech Stack

- **IaC:** Terraform
- **Container Orchestration:** Kubernetes / Docker Compose
- **CI/CD:** GitHub Actions
- **Cloud Provider:** AWS / GCP / Azure
- **Monitoring:** Prometheus + Grafana
- **Logging:** ELK Stack / CloudWatch

## Getting Started

### Prerequisites

- Terraform >= 1.5.0
- kubectl >= 1.27
- Docker >= 24.0
- AWS CLI / gcloud / az CLI
- Helm >= 3.12

### Initial Setup

```bash
# Install dependencies
terraform init

# Review planned changes
terraform plan

# Apply infrastructure
terraform apply
```

## Project Structure

```
infrastructure/
├── terraform/
│   ├── modules/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── main.tf
├── kubernetes/
│   ├── deployments/
│   ├── services/
│   ├── configmaps/
│   └── secrets/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── monitoring/
│   ├── prometheus/
│   └── grafana/
└── scripts/
    ├── deploy.sh
    └── rollback.sh
```

## Environment Configuration

### Development

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Staging

```bash
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

### Production

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## Kubernetes Deployments

### Deploy Application

```bash
# Apply all manifests
kubectl apply -f kubernetes/

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### Update Deployment

```bash
# Update image
kubectl set image deployment/app-name container-name=new-image:tag

# Rollout status
kubectl rollout status deployment/app-name

# Rollback if needed
kubectl rollout undo deployment/app-name
```

## Docker Operations

### Build Images

```bash
# Build frontend
docker build -t myapp-frontend:latest -f docker/frontend.Dockerfile .

# Build backend
docker build -t myapp-backend:latest -f docker/backend.Dockerfile .
```

### Run Locally

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Environment Variables

### Terraform Variables

Create `terraform.tfvars`:

```hcl
# AWS Configuration
aws_region = "us-east-1"
aws_account_id = "123456789012"

# Project Configuration
project_name = "myapp"
environment = "dev"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Application Configuration
app_replicas = 3
instance_type = "t3.medium"
```

### Kubernetes Secrets

```bash
# Create secret from file
kubectl create secret generic db-credentials \
  --from-file=./secrets/db-password.txt

# Create secret from literal
kubectl create secret generic api-key \
  --from-literal=api-key='your-api-key'
```

## Infrastructure Components

### Networking

- VPC with public and private subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Security Groups

### Compute

- ECS/EKS Cluster
- Auto Scaling Groups
- Load Balancers (ALB/NLB)

### Storage

- RDS (PostgreSQL)
- ElastiCache (Redis)
- S3 Buckets
- EBS Volumes

### Security

- IAM Roles and Policies
- KMS Encryption Keys
- Secrets Manager
- Certificate Manager (SSL/TLS)

## Monitoring and Logging

### Prometheus

```bash
# Deploy Prometheus
helm install prometheus prometheus-community/prometheus

# Access Prometheus UI
kubectl port-forward svc/prometheus-server 9090:80
```

### Grafana

```bash
# Deploy Grafana
helm install grafana grafana/grafana

# Get admin password
kubectl get secret grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Access Grafana UI
kubectl port-forward svc/grafana 3000:80
```

### Logging

```bash
# View application logs
kubectl logs -f deployment/app-name

# View logs from specific pod
kubectl logs -f pod-name

# View logs from all pods in deployment
kubectl logs -f -l app=app-name
```

## Disaster Recovery

### Backups

```bash
# Backup database
./scripts/backup-database.sh

# Backup Kubernetes state
kubectl get all --all-namespaces -o yaml > backup.yaml
```

### Restore

```bash
# Restore database
./scripts/restore-database.sh backup-file.sql

# Restore Kubernetes resources
kubectl apply -f backup.yaml
```

## Security Best Practices

- ✅ Enable encryption at rest and in transit
- ✅ Use least privilege IAM policies
- ✅ Rotate secrets regularly
- ✅ Enable MFA for critical operations
- ✅ Use private subnets for databases
- ✅ Implement network policies
- ✅ Enable audit logging
- ✅ Scan container images for vulnerabilities
- ✅ Use managed services when possible
- ✅ Keep infrastructure code in version control

## Cost Optimization

- Use auto-scaling to match demand
- Schedule non-production environments (shut down at night)
- Use spot instances for non-critical workloads
- Implement lifecycle policies for S3
- Monitor and delete unused resources
- Right-size instances based on metrics

## Deployment

The infrastructure is automatically updated on push to `main` branch via GitHub Actions.

### Deployment Checklist

- [ ] Terraform plan reviewed
- [ ] Changes approved by team lead
- [ ] Backup taken
- [ ] Monitoring alerts configured
- [ ] Rollback plan documented

## Troubleshooting

### Terraform Issues

**State lock error:**
```bash
# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

**State drift:**
```bash
# Refresh state
terraform refresh

# Show differences
terraform plan
```

### Kubernetes Issues

**Pod not starting:**
```bash
# Describe pod
kubectl describe pod pod-name

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

**Service not accessible:**
```bash
# Check service
kubectl describe service service-name

# Check endpoints
kubectl get endpoints
```

## Contributing

1. Create a feature branch from `develop`
2. Make infrastructure changes
3. Run `terraform plan` and review output
4. Test in dev environment first
5. Submit a pull request
6. Wait for code review and approval

## Resources

- **Terraform Documentation:** https://www.terraform.io/docs
- **Kubernetes Documentation:** https://kubernetes.io/docs
- **AWS Documentation:** https://docs.aws.amazon.com
- **Docker Documentation:** https://docs.docker.com

## License

See LICENSE file for details.
