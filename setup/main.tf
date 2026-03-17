terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------
# Phase 1: IAM Foundation
# -----------------------------------------------------
module "iam" {
  source = "./modules/iam"

  users                           = var.users
  admin_group_name                = var.admin_group_name
  admin_group_path                = var.admin_group_path
  minimum_password_length         = var.minimum_password_length
  max_password_age                = var.max_password_age
  password_reuse_prevention       = var.password_reuse_prevention
  audit_role_max_session_duration = var.audit_role_max_session_duration
  trusted_principal_arns          = var.trusted_principal_arns
  audit_role_external_id          = var.audit_role_external_id
  tags                            = local.common_tags
}

# -----------------------------------------------------
# Phase 3 + 4 + 6: CloudTrail, Lake, CloudWatch Alerts
# -----------------------------------------------------
module "cloudtrail" {
  source = "./modules/cloudTrail"

  bucket_name              = var.cloudtrail_bucket_name
  region                   = var.region
  cloud_trail_name         = var.cloud_trail_name
  security_team_role_arn   = module.iam.security_audit_role_arn
  sns_endpoint             = var.sns_endpoint
  sns_topic_name           = var.sns_topic_name
  log_group_retention_days = var.log_group_retention_days
  lake_retention_days      = var.lake_retention_days
  kms_alias_name           = var.kms_alias_name
  kms_deletion_window_days = var.kms_deletion_window_days
  tags                     = local.common_tags
}

# -----------------------------------------------------
# Phase 5: Security Hub
# -----------------------------------------------------
module "security_hub" {
  source = "./modules/security_hub"

  region               = var.region
  enable_cis_benchmark = var.enable_cis_benchmark
  enable_fsbp          = var.enable_fsbp
}
