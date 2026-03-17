resource "aws_iam_policy" "security_auditor" {
  name        = "SecurityAuditorPolicy"
  description = "Read-only access to CloudTrail, Security Hub, CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecurityAuditReadOnly"
        Effect = "Allow"
        Action = [
          "cloudtrail:GetTrail",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:DescribeTrails",
          "cloudtrail:LookupEvents",
          "cloudtrail:ListTrails",
          "securityhub:GetFindings",
          "securityhub:ListFindings",
          "securityhub:DescribeHub",
          "securityhub:GetInsights",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
