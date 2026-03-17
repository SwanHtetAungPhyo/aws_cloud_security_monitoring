resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/${var.cloud_trail_name}"
  retention_in_days = var.log_group_retention_days
  kms_key_id        = aws_kms_key.cloudtrail.arn
  tags              = var.tags
}
