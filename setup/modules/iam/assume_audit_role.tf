locals {
  # Default to same-account root if no trusted principals provided
  trusted_principals = length(var.trusted_principal_arns) > 0 ? var.trusted_principal_arns : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

resource "aws_iam_role" "security_audit_role" {
  name = "SecurityAuditRole"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.trusted_principals }
      Action    = "sts:AssumeRole"
      Condition = var.audit_role_external_id != "" ? {
        StringEquals = {
          "sts:ExternalId" = var.audit_role_external_id
        }
      } : {}
    }]
  })

  max_session_duration = var.audit_role_max_session_duration
}

resource "aws_iam_role_policy" "audit_permissions" {
  name = "AuditPermissions"
  role = aws_iam_role.security_audit_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:LookupEvents",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:ListTrails",
          "cloudtrail:GetEventDataStore",
          "cloudtrail:ListEventDataStores",
          "cloudtrail:StartQuery",
          "cloudtrail:GetQueryResults",
          "securityhub:GetFindings",
          "securityhub:DescribeHub",
          "securityhub:ListFindings",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}
