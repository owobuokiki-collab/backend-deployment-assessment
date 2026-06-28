# MuchTodo Backend Deployment Assessment

## Overview
This repository contains the infrastructure and containerization setup for the MuchTodo Golang backend API, deployed on AWS using Terraform and Docker.

## Prerequisites
- Terraform >= 1.0
- Docker and Docker Compose
- AWS CLI configured with valid credentials
- An AWS account with EC2, VPC, and ALB permissions

---

## Phase 1: Infrastructure Provisioning (Terraform)

### 1. Navigate to the terraform directory
```bash
cd terraform
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Create your tfvars file
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 4. Preview the infrastructure
```bash
terraform plan
```

### 5. Apply the infrastructure
```bash
terraform apply
```

### 6. Note the outputs
After apply completes, Terraform will output:
- VPC ID
- ALB DNS name
- Bastion public IP
- Backend server private IP

---

## Phase 2: Docker Setup (Local)

### 1. Build the Docker image
```bash
docker compose build
```

### 2. Start the containers
```bash
docker compose up -d
```

### 3. Verify the backend is running
```bash
curl http://localhost:8080/health
```

---

## Phase 3: Deployment to EC2

### 1. SSH into Bastion host
```bash
ssh -i your-key.pem ec2-user@<bastion-public-ip>
```

### 2. SSH from Bastion into Backend server
```bash
ssh -i your-key.pem ec2-user@<backend-private-ip>
```

### 3. Clone the repository
```bash
git clone https://github.com/owobuokiki-collab/backend-deployment-assessment.git
cd backend-deployment-assessment
```

### 4. Start the application
```bash
docker compose up -d
```

### 5. Verify via ALB
```bash
curl http://<alb-dns-name>/health
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| PORT | Application port | 8080 |
| MONGO_URI | MongoDB connection string | mongodb://mongodb:27017 |
| DB_NAME | Database name | much_todo_db |
| JWT_SECRET_KEY | JWT signing key | - |
| JWT_EXPIRATION_HOURS | JWT token expiry | 72 |
| ENABLE_CACHE | Enable Redis cache | false |
| LOG_LEVEL | Log level | INFO |
| LOG_FORMAT | Log format | json |

---

## Teardown / Cleanup

### Stop Docker containers
```bash
docker compose down -v
```

### Destroy AWS infrastructure
```bash
cd terraform
terraform destroy
```