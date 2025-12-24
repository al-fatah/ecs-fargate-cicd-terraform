data "aws_caller_identity" "current" {}

# # GitHub OIDC Provider (one per AWS account)
# resource "aws_iam_openid_connect_provider" "github" {
#   url = "https://token.actions.githubusercontent.com"

#   client_id_list = ["sts.amazonaws.com"]

#   # GitHub Actions OIDC thumbprint (commonly used)
#   # If your org/security requires exact thumbprint updates, you can adjust later.
#   thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
# }
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# IAM Role assumed by GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${local.name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          # ✅ IMPORTANT: update <OWNER>/<REPO> to your GitHub repo
          "token.actions.githubusercontent.com:sub" = "repo:al-fatah/ecs-fargate-cicd-terraform:*"
        }
      }
    }]
  })
}

# Permissions needed for: ECR push + ECS deploy + read task definition
resource "aws_iam_policy" "github_actions" {
  name = "${local.name}-github-actions-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ECR: login + push
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories"
        ],
        Resource = "*"
      },

      # ECS deploy
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ],
        Resource = "*"
      },

      # Pass ECS task execution role to ECS when registering task definitions
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.ecs_task_execution.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
