resource "aws_cloudtrail" "multi_region_trail" {
  name                          = var.cloud_trail_name
  s3_bucket_name                = aws_s3_bucket.cloud_trail_logs_store_bucket.id
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  tags                          = var.tags

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3"]
    }
  }

  sns_topic_name             = aws_sns_topic.security_alerts.arn
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloud_watch_trail_iam_role.arn
  depends_on                 = [aws_s3_bucket_policy.cloud_trail_logs_store_bucket]
}
