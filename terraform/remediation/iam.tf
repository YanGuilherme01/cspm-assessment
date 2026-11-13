# Fixes F03, F04, F13. F07 (root MFA) is a manual console step and cannot be set by Terraform.

data "aws_iam_policy_document" "ci_deploy" { # F04: scoped replacement for Action "*"
  statement {
    sid       = "DeployArtifacts"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.artifact_bucket}", "arn:aws:s3:::${var.artifact_bucket}/*"]
  }
}

resource "aws_iam_role" "ci" { # F03: short-lived role credentials via GitHub OIDC instead of access keys
  name = "ci-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "ci" {
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_deploy.json
}

resource "aws_iam_account_password_policy" "strong" { # F13
  minimum_password_length        = 14
  require_symbols                = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_lowercase_characters   = true
  password_reuse_prevention      = 24
  allow_users_to_change_password = true
}

variable "artifact_bucket" { type = string }
variable "github_oidc_provider_arn" { type = string }
variable "github_repo" { type = string }
