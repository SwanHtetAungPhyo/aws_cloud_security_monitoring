variable "bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log storage"
  type        = string
}

variable "region" {
  description = "AWS region for the CloudTrail trail"
  type        = string
}

variable "cloud_trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
}

variable "security_team_role_arn" {
  description = "IAM role ARN for the security team to decrypt CloudTrail logs"
  type        = string
}

variable "sns_endpoint" {
  description = "Email endpoint for SNS security alert notifications"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic for security alerts"
  type        = string
  default     = "security-alerts"
}

variable "log_group_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 365
}

variable "lake_retention_days" {
  description = "Number of days to retain CloudTrail Lake event data"
  type        = number
  default     = 7
}

variable "kms_alias_name" {
  description = "Alias name for the CloudTrail KMS key (without alias/ prefix)"
  type        = string
  default     = "cloudtrail-logs"
}

variable "kms_deletion_window_days" {
  description = "Number of days before KMS key deletion after it is scheduled"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
