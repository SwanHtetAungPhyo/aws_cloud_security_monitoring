variable "region" {
  description = "AWS region for Security Hub standards ARNs"
  type        = string
}

variable "enable_cis_benchmark" {
  description = "Whether to enable the CIS AWS Foundations Benchmark standard"
  type        = bool
  default     = true
}

variable "enable_fsbp" {
  description = "Whether to enable the AWS Foundational Security Best Practices standard"
  type        = bool
  default     = true
}