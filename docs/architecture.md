# Architecture

## Flow
1. Developer pushes to `dev` or `main`
2. GitHub Actions assumes AWS IAM Role via OIDC
3. Build Docker image and push to Amazon ECR
4. Download current ECS task definition
5. Render new task definition with updated image tag (commit SHA)
6. Deploy to ECS service and wait for stability
7. ALB routes traffic to ECS tasks
8. Container logs go to CloudWatch Logs

## Environments
- DEV branch → DEV ECS service
- MAIN branch → PROD ECS service (approval gated)
