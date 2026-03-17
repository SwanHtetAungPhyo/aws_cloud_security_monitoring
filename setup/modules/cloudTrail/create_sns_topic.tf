resource "aws_sns_topic" "security_alerts" {
  name              = var.sns_topic_name
  kms_master_key_id = aws_kms_key.cloudtrail.arn
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_endpoint
}
