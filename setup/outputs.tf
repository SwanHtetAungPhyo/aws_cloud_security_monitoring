# -----------------------------------------------------
# IAM
# -----------------------------------------------------
output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = module.iam.admin_group_name
}

output "admin_group_arn" {
  description = "ARN of the admin IAM group"
  value       = module.iam.admin_group_arn
}

output "iam_user_names" {
  description = "List of created IAM user names"
  value       = module.iam.iam_user_names
}

output "security_audit_role_arn" {
  description = "ARN of the Security Audit IAM role (use with assume-audit-role.sh)"
  value       = module.iam.security_audit_role_arn
}

output "force_mfa_policy_arn" {
  description = "ARN of the Force MFA policy"
  value       = module.iam.force_mfa_policy_arn
}

# -----------------------------------------------------
# CloudTrail
# -----------------------------------------------------
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.cloudtrail.cloudtrail_arn
}

output "cloudtrail_s3_bucket_name" {
  description = "Name of the CloudTrail logs S3 bucket"
  value       = module.cloudtrail.s3_bucket_name
}

output "cloudtrail_kms_key_arn" {
  description = "ARN of the KMS key used for CloudTrail encryption"
  value       = module.cloudtrail.kms_key_arn
}

output "cloudtrail_log_group_arn" {
  description = "ARN of the CloudTrail CloudWatch log group"
  value       = module.cloudtrail.log_group_arn
}

output "cloudtrail_sns_topic_arn" {
  description = "ARN of the security alerts SNS topic"
  value       = module.cloudtrail.sns_topic_arn
}

output "cloudtrail_lake_event_data_store_id" {
  description = "ID of the CloudTrail Lake event data store"
  value       = module.cloudtrail.event_data_store_id
}

# -----------------------------------------------------
# Security Hub
# -----------------------------------------------------
output "securityhub_account_id" {
  description = "ID of the Security Hub account resource"
  value       = module.security_hub.securityhub_account_id
}
