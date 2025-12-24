# ECS Fargate CI/CD with Terraform

End-to-end CI/CD pipeline using **Terraform**, **GitHub Actions**, and **AWS ECS Fargate**.  
Infrastructure is provisioned with Terraform, while application deployments are fully automated via GitHub Actions using **OIDC (no static AWS keys)**.

This project demonstrates real-world DevOps practices: multi-environment deployments, IaC validation, controlled production releases, and least-privilege access.

---

## Architecture

### High-level flow
1. Developer pushes code to `dev` or `main`
2. GitHub Actions assumes an AWS IAM Role via **OIDC**
3. Docker image is built and pushed to **Amazon ECR**
4. ECS task definition is updated with the new image
5. ECS service performs a rolling deployment on **Fargate**
6. **Application Load Balancer (ALB)** routes traffic to tasks
7. Application logs are sent to **CloudWatch Logs**

See: `docs/architecture.md` for details.

---

## Environments

| Environment | Git Branch | Deployment Target | Approval |
|-----------|-----------|-------------------|---------|
| DEV | `dev` | ECS Fargate (DEV) | No |
| PROD | `main` | ECS Fargate (PROD) | Yes (GitHub Environment) |

### Live endpoints
- **DEV**
  - Health check:  
    http://hello-ecs-dev-alb-1559499837.us-east-1.elb.amazonaws.com/health

- **PROD**
  - Health check:  
    http://hello-ecs-prod-alb-615093892.us-east-1.elb.amazonaws.com/health

---

## CI/CD Pipelines

### Terraform CI
Workflow: `.github/workflows/terraform-ci.yml`

Runs on every push and pull request:
- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate`

Purpose:
- Enforces consistent formatting
- Prevents invalid infrastructure code from being merged
- Does **not** touch AWS resources

---

### Application CD (ECS Deployment)
Workflow: `.github/workflows/deploy-ecs.yml`

Triggered by:
- Push to `dev` → deploys to DEV
- Push to `main` → deploys to PROD (approval gated)

Steps:
1. Assume AWS IAM role using GitHub OIDC
2. Build Docker image
3. Push image to Amazon ECR
4. Download current ECS task definition
5. Render task definition with new image tag (commit SHA)
6. Deploy updated task definition to ECS service
7. Wait for service stability

---

## Infrastructure (Terraform)

Terraform environments:
```
terraform/
└── envs/
    ├── dev/
    └── prod/
```

Provisioned resources include:
- VPC with public subnets
- Application Load Balancer
- ECS Cluster (Fargate)
- ECS Service and Task Definition
- Amazon ECR repository
- CloudWatch Log Group
- IAM roles (ECS execution + GitHub Actions)

---

## Repository Structure

```
.
├── app/
├── terraform/
│   └── envs/
│       ├── dev/
│       └── prod/
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml
│       └── deploy-ecs.yml
├── docs/
│   └── architecture.md
├── .gitignore
└── README.md
```

---

## Running Locally

```bash
cd app
docker build -t hello-ecs:local .
docker run -p 3000:3000 hello-ecs:local
```

Test:
```bash
curl http://localhost:3000/health
```

---

## Deployment Flow

### DEV
```bash
git checkout dev
git push origin dev
```
→ Automatically deploys to DEV ECS service

### PROD
```bash
git checkout main
git merge dev
git push origin main
```
→ Triggers PROD deployment  
→ Requires manual approval via GitHub Environments

---

## Security

- No long-lived AWS access keys
- GitHub Actions uses **OIDC** to assume IAM roles
- IAM policies follow least-privilege principles
- Separate IAM roles per environment (DEV / PROD)

---

## Observability & Troubleshooting

- Container logs: **CloudWatch Logs**
- ECS service events show deployment progress and failures
- `wait-for-service-stability: true` ensures failed deployments surface early

---

## Cost Notes (FinOps)

- ECS Fargate avoids EC2 management overhead
- DEV runs with minimal desired count
- CloudWatch log retention is limited
- Infrastructure is environment-isolated to avoid cost leakage

---

## What This Project Demonstrates

- Infrastructure as Code with Terraform
- Safe CI validation for IaC
- Production-grade CD with ECS Fargate
- Multi-environment deployment strategy
- Secure authentication using GitHub OIDC
- Realistic DevOps workflows used in production teams

---

## Author - Alfatah Jalalludin
DevOps portfolio project demonstrating AWS ECS, Terraform, and CI/CD best practices.
