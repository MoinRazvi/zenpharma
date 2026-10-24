
# GitHub Actions OIDC provider
# Allows GitHub Actions to authenticate to AWS without long-lived access keys.

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name    = "${var.project}-${var.env}-github-actions-oidc"
    Project = var.project
    Env     = var.env
  }
}

# Trust policy: only authorized branches in the ZenPharma repository
# can assume this IAM role.

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"

      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"

  values = [
    "repo:${var.github_org}@132929507/${var.github_repo}@1400125651:ref:refs/heads/main",
    "repo:${var.github_org}@132929507/${var.github_repo}@1400125651:ref:refs/heads/develop",
    "repo:${var.github_org}@132929507/${var.github_repo}@1400125651:ref:refs/heads/release/*"
  ]
}
  }
}

# IAM role assumed by GitHub Actions workflows.

resource "aws_iam_role" "github_actions_ci" {
  name               = "${var.project}-${var.env}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600

  tags = {
    Name    = "${var.project}-${var.env}-github-actions-role"
    Project = var.project
    Env     = var.env
  }
}

# Permissions required to authenticate to ECR, push images,
# and describe EKS clusters.
#
# Scope ECR write permissions to the project's repositories.
# EKS permissions are limited to describing/listing clusters.

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid    = "ECRAuthorization"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECRImagePushPull"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.ecr_repository_prefix}*"
    ]
  }

  statement {
    sid    = "EKSClusterDiscovery"
    effect = "Allow"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_ci" {
  name        = "${var.project}-${var.env}-github-actions-policy"
  description = "Permissions for ZenPharma GitHub Actions CI/CD"
  policy      = data.aws_iam_policy_document.github_actions_permissions.json

  tags = {
    Project = var.project
    Env     = var.env
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_ci" {
  role       = aws_iam_role.github_actions_ci.name
  policy_arn = aws_iam_policy.github_actions_ci.arn
}

# Outputs for use by CI/CD configuration or other Terraform modules.

output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions_ci.arn
}

output "github_actions_role_name" {
  description = "IAM role name assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions_ci.name
}

output "github_actions_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
