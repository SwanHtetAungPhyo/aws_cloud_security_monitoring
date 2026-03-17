# Password Policy
output "password_policy_expire_passwords" {
  description = "Whether the password policy requires passwords to expire"
  value       = aws_iam_account_password_policy.restrict_password.expire_passwords
}

output "password_policy_minimum_length" {
  description = "Minimum password length enforced by the account password policy"
  value       = aws_iam_account_password_policy.restrict_password.minimum_password_length
}

output "password_policy_max_age" {
  description = "Maximum number of days a password can be used before it must be changed"
  value       = aws_iam_account_password_policy.restrict_password.max_password_age
}

# Admin Group
output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = aws_iam_group.admin_group.name
}

output "admin_group_arn" {
  description = "ARN of the admin IAM group"
  value       = aws_iam_group.admin_group.arn
}

# IAM Users
output "iam_user_names" {
  description = "List of created IAM user names"
  value       = [for user in aws_iam_user.users : user.name]
}

output "iam_user_arns" {
  description = "Map of IAM user names to their ARNs"
  value       = { for k, user in aws_iam_user.users : k => user.arn }
}

# IAM Policies
output "force_mfa_policy_arn" {
  description = "ARN of the Force MFA policy"
  value       = aws_iam_policy.force_mfa.arn
}

output "security_auditor_policy_arn" {
  description = "ARN of the Security Auditor policy"
  value       = aws_iam_policy.security_auditor.arn
}

output "incident_responder_policy_arn" {
  description = "ARN of the Incident Responder policy"
  value       = aws_iam_policy.incident_responder.arn
}

output "dev_read_only_policy_arn" {
  description = "ARN of the Dev Read Only policy"
  value       = aws_iam_policy.dev_read_only.arn
}

# Audit Role
output "security_audit_role_arn" {
  description = "ARN of the Security Audit IAM role"
  value       = aws_iam_role.security_audit_role.arn
}

output "security_audit_role_name" {
  description = "Name of the Security Audit IAM role"
  value       = aws_iam_role.security_audit_role.name
}
