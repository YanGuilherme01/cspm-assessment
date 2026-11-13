# Fixes F05, F08, F12.

resource "aws_vpc_security_group_ingress_rule" "ssh_bastion_only" { # F05: replace 0.0.0.0/0 (or remove and use SSM)
  security_group_id = var.security_group_id
  cidr_ipv4         = var.bastion_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/vpc/flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "flow" {
  name = "vpc-flow-logs"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "flow" {
  role = aws_iam_role.flow.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      Resource = "${aws_cloudwatch_log_group.flow.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" { # F08
  vpc_id          = var.vpc_id
  traffic_type    = "ALL"
  log_destination = aws_cloudwatch_log_group.flow.arn
  iam_role_arn    = aws_iam_role.flow.arn
}

resource "aws_ebs_encryption_by_default" "on" { enabled = true } # F12

variable "security_group_id" { type = string }
variable "vpc_id" { type = string }
variable "bastion_cidr" { type = string }
