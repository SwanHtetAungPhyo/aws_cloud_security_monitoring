terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "event_data_store_name" {
  description = "Name of the CloudTrail Lake event data store"
  type        = string
}

variable "lake_retention_days" {
  description = "Number of days to retain CloudTrail Lake event data"
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "KMS key ARN for encrypting CloudTrail Lake event data store"
  type        = string
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

resource "aws_cloudtrail_event_data_store" "event_data_store" {
  name                           = var.event_data_store_name
  retention_period               = var.lake_retention_days
  multi_region_enabled           = true
  organization_enabled           = false
  termination_protection_enabled = false
  kms_key_id                     = var.kms_key_id
  tags                           = var.tags

  advanced_event_selector {
    name = "ManagementEvents"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }
}

output "event_data_store_id" {
  description = "ID of the CloudTrail Lake event data store"
  value       = aws_cloudtrail_event_data_store.event_data_store.id
}

output "event_data_store_arn" {
  description = "ARN of the CloudTrail Lake event data store"
  value       = aws_cloudtrail_event_data_store.event_data_store.arn
}
