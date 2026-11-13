# Fixes F01, F02, F09, F10, F14. Apply after the insecure lab (same state) or adapt to your module layout.

resource "aws_kms_key" "data" {
  description         = "Default encryption for lab buckets"
  enable_key_rotation = true # F10
}

resource "aws_s3_account_public_access_block" "account" { # F01 (account-wide guardrail)
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" { # F02
  bucket = var.data_bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "data" { # F09
  bucket = var.data_bucket
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_logging" "data" { # F14
  bucket        = var.data_bucket
  target_bucket = var.log_bucket
  target_prefix = "s3-access/${var.data_bucket}/"
}

variable "data_bucket" { type = string }
variable "log_bucket" { type = string }
