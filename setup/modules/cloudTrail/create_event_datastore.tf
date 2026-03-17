resource "aws_cloudtrail_event_data_store" "management_events" {
  name                           = "${var.cloud_trail_name}-lake-datastore"
  retention_period               = var.lake_retention_days
  multi_region_enabled           = true
  organization_enabled           = false
  termination_protection_enabled = false
  kms_key_id                     = aws_kms_key.cloudtrail.arn
  tags                           = var.tags

  advanced_event_selector {
    name = "ManagementEvents"

    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
  }
}
