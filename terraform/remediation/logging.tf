# Fixes F06, F11.

resource "aws_s3_bucket" "trail" {
  bucket = var.trail_bucket
}

data "aws_caller_identity" "me" {}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid = "AclCheck", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" }, Action = "s3:GetBucketAcl", Resource = aws_s3_bucket.trail.arn },
      { Sid      = "Write", Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" }, Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.trail.arn}/AWSLogs/${data.aws_caller_identity.me.account_id}/*",
      Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } } }
    ]
  })
}

resource "aws_cloudtrail" "org" { # F06
  name                          = "multi-region"
  s3_bucket_name                = aws_s3_bucket.trail.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.trail]
}

resource "aws_guardduty_detector" "main" { enable = true } # F11 (repeat per active region)

variable "trail_bucket" { type = string }
