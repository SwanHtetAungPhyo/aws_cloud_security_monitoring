resource "aws_iam_role" "cloud_watch_trail_iam_role" {
  name = "${var.cloud_trail_name}-cloudwatch-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.cloud_trail_name}-cloudwatch-policy"
  role = aws_iam_role.cloud_watch_trail_iam_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
    }]
  })
}
