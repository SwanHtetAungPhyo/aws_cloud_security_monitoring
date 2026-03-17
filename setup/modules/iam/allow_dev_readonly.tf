resource "aws_iam_policy" "dev_read_only" {
  name        = "DevReadOnlyPolicy"
  description = "Read-only access to specific services for developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DevReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "rds:Describe*",
          "lambda:GetFunction",
          "lambda:ListFunctions",
          "ecs:Describe*",
          "ecs:List*",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}
