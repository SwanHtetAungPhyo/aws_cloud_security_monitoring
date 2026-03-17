output "securityhub_account_id" {
  description = "ID of the Security Hub account resource"
  value       = aws_securityhub_account.main.id
}

output "fsbp_subscription_arn" {
  description = "ARN of the FSBP standards subscription"
  value       = var.enable_fsbp ? aws_securityhub_standards_subscription.fsbp[0].standards_arn : null
}

output "cis_subscription_arn" {
  description = "ARN of the CIS Benchmark standards subscription"
  value       = var.enable_cis_benchmark ? aws_securityhub_standards_subscription.cis[0].standards_arn : null
}
