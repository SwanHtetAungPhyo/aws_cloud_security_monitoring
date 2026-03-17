variable "users" {
  description = "List of IAM usernames to create and add to the admin group"
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
  description = "Maximum number of days a password can be used before it must be changed (0 = no expiry)"
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
  description = "List of IAM ARNs trusted to assume the security audit role (for cross-account, use the remote account root ARN)"
  type        = list(string)
  default     = []
}

variable "audit_role_external_id" {
  description = "External ID for cross-account role assumption (leave empty to disable)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
