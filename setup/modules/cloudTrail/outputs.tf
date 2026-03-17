# S3 Bucket
output "s3_bucket_id" {
  description = "ID of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloud_trail_logs_store_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloud_trail_logs_store_bucket.arn
}

output "s3_bucket_name" {
  description = "Name of the CloudTrail logs S3 bucket"
  value       = aws_s3_bucket.cloud_trail_logs_store_bucket.bucket
}

# KMS
output "kms_key_id" {
  description = "ID of the KMS key used for CloudTrail log encryption"
  value       = aws_kms_key.cloudtrail.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for CloudTrail log encryption"
  value       = aws_kms_key.cloudtrail.arn
}

output "kms_alias_arn" {
  description = "ARN of the KMS alias for CloudTrail logs"
  value       = aws_kms_alias.cloudtrail.arn
}

# CloudTrail
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.multi_region_trail.arn
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.multi_region_trail.name
}

# CloudTrail Lake
output "event_data_store_id" {
  description = "ID of the CloudTrail Lake event data store"
  value       = aws_cloudtrail_event_data_store.management_events.id
}

output "event_data_store_arn" {
  description = "ARN of the CloudTrail Lake event data store"
  value       = aws_cloudtrail_event_data_store.management_events.arn
}

# CloudWatch
output "log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.arn
}

output "log_group_name" {
  description = "Name of the CloudTrail CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail_log_group.name
}

# SNS
output "sns_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the security alerts SNS topic"
  value       = aws_sns_topic.security_alerts.name
}

# Account
output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
