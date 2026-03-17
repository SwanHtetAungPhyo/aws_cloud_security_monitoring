resource "aws_sns_topic" "security_alerts" {
  name              = var.sns_topic_name
  kms_master_key_id = aws_kms_key.cloudtrail.arn
  tags              = var.tags
}

resource "aws_sns_topic_policy" "cloudtrail_publish" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudTrailPublish"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.security_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloud_trail_name}"
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_endpoint
}
