# -----------------------------------------------------
# General
# -----------------------------------------------------
variable "region" {
  description = "AWS region to deploy all resources"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "cloud-security-platform"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------
# IAM (Phase 1 + 2)
# -----------------------------------------------------
variable "users" {
  description = "List of IAM usernames to create"
  type        = list(string)
  default     = []
}

variable "admin_group_name" {
  description = "Name of the IAM admin group"
  type        = string
  default     = "cloud_admin"
}

variable "admin_group_path" {
  description = "Path for the IAM admin group"
  type        = string
  default     = "/admins/"
}

variable "minimum_password_length" {
  description = "Minimum password length for the account password policy"
  type        = number
  default     = 14
}

variable "max_password_age" {
  description = "Maximum number of days a password can be used before it must be changed"
  type        = number
  default     = 90
}

variable "password_reuse_prevention" {
  description = "Number of previous passwords that cannot be reused"
  type        = number
  default     = 24
}

variable "audit_role_max_session_duration" {
  description = "Maximum session duration in seconds for the security audit role"
  type        = number
  default     = 3600
}

variable "trusted_principal_arns" {
  description = "List of IAM ARNs trusted to assume the security audit role"
  type        = list(string)
  default     = []
}

variable "audit_role_external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = ""
}

# -----------------------------------------------------
# CloudTrail (Phase 3 + 4 + 6)
# -----------------------------------------------------
variable "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log storage"
  type        = string
}

variable "cloud_trail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "security-audit-trail"
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
  description = "Alias name for the CloudTrail KMS key"
  type        = string
  default     = "cloudtrail-logs"
}

variable "kms_deletion_window_days" {
  description = "Number of days before KMS key deletion"
  type        = number
  default     = 30
}

# -----------------------------------------------------
# Security Hub (Phase 5)
# -----------------------------------------------------
variable "enable_cis_benchmark" {
  description = "Whether to enable the CIS AWS Foundations Benchmark"
  type        = bool
  default     = true
}

variable "enable_fsbp" {
  description = "Whether to enable the AWS Foundational Security Best Practices"
  type        = bool
  default     = true
}
