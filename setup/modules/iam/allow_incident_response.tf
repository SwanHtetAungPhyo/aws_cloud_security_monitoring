resource "aws_iam_policy" "incident_responder" {
  name        = "IncidentResponderPolicy"
  description = "Limited write access to isolate resources during incidents"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IsolateEC2"
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:ModifyInstanceAttribute",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateSnapshot"
        ]
        Resource = "*"
      },
      {
        Sid    = "IsolateIAM"
        Effect = "Allow"
        Action = [
          "iam:AttachUserPolicy",
          "iam:ListAttachedUserPolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadLogs"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudtrail:LookupEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
