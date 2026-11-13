# INTENTIONALLY INSECURE LAB. Deploy only in an isolated sandbox account with no real data.
# Each resource is tagged with the finding ID it is designed to trigger.
# Destroy right after the scan: terraform destroy

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.60" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = { Project = "cspm-insecure-lab", Owner = var.owner, Ephemeral = "true" } }
}

variable "region" { default = "us-east-1" }
variable "owner" { default = "portfolio-lab" }

resource "random_id" "suffix" { byte_length = 4 }

# F01 public ACL · F02 no default encryption · F09 no versioning · F14 no access logging
resource "aws_s3_bucket" "public_data" {
  bucket        = "cspm-lab-public-${random_id.suffix.hex}"
  force_destroy = true
  tags          = { Finding = "F01,F02,F09,F14" }
}

resource "aws_s3_bucket_ownership_controls" "public_data" {
  bucket = aws_s3_bucket.public_data.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_public_access_block" "public_data" {
  bucket                  = aws_s3_bucket.public_data.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "public_data" {
  depends_on = [aws_s3_bucket_ownership_controls.public_data, aws_s3_bucket_public_access_block.public_data]
  bucket     = aws_s3_bucket.public_data.id
  acl        = "public-read"
}

# F03 long-lived access key · F04 wildcard inline policy
resource "aws_iam_user" "legacy_ci" {
  name = "cspm-lab-legacy-ci"
  tags = { Finding = "F03,F04" }
}

resource "aws_iam_access_key" "legacy_ci" { user = aws_iam_user.legacy_ci.name }

resource "aws_iam_user_policy" "admin_wildcard" {
  name = "everything"
  user = aws_iam_user.legacy_ci.name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }]
  })
}

# F13 weak password policy
resource "aws_iam_account_password_policy" "weak" {
  minimum_password_length = 8
  require_symbols         = false
}

# F05 SSH open to the internet · F08 no flow logs
resource "aws_vpc" "lab" {
  cidr_block = "10.42.0.0/16"
  tags       = { Name = "cspm-lab", Finding = "F08" }
}

resource "aws_security_group" "ssh_world" {
  name   = "cspm-lab-ssh-world"
  vpc_id = aws_vpc.lab.id
  tags   = { Finding = "F05" }

  ingress {
    description = "SSH from anywhere (intentional finding)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# F10 customer-managed key without rotation
resource "aws_kms_key" "no_rotation" {
  description         = "cspm-lab key without rotation"
  enable_key_rotation = false
  tags                = { Finding = "F10" }
}

# F06 (no CloudTrail), F07 (root MFA), F11 (GuardDuty off) and F12 (EBS default encryption off)
# are produced by the absence of configuration, which is the default state of a new account.

output "lab_bucket" { value = aws_s3_bucket.public_data.bucket }
