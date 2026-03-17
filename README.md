# Cloud Security & Compliance Monitoring Platform

## Architecture

![Architecture Diagram](diagrams/cloud-security-architecture.drawio.png)

## Overview

<!-- What this project does and why it exists -->

## Features

<!-- Bullet list of key capabilities -->

## Project Structure

```
.
├── setup/
│   ├── main.tf                          # Root module — wires all modules together
│   ├── variables.tf                     # Root input variables
│   ├── outputs.tf                       # Root outputs
│   ├── terraform.tfvars.example         # Example variable values
│   └── modules/
│       ├── iam/                         # Phase 1 + 2: IAM Foundation & STS
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── create_users.tf
│       │   ├── manage_group.tf
│       │   ├── enforce_password.tf
│       │   ├── enforce_mfa.tf
│       │   ├── allow_security_audit.tf
│       │   ├── allow_incident_response.tf
│       │   ├── allow_dev_readonly.tf
│       │   └── assume_audit_role.tf
│       ├── cloudTrail/                  # Phase 3 + 4 + 6: Trail, Lake, Alerts
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   ├── create_log_bucket.tf
│       │   ├── encrypt_logs.tf
│       │   ├── enable_trail.tf
│       │   ├── create_event_datastore.tf
│       │   ├── query_lake.tf
│       │   ├── create_cloud_watch_log.tf
│       │   ├── create_cloudtrail_loggroup_iam.tf
│       │   ├── create_sns_topic.tf
│       │   ├── create_console_log_wach_metric.tf
│       │   ├── create_cloud_watch_root_acc_usage.tf
│       │   ├── create_cloud_watch_unauth_api_metrics.tf
│       │   └── create_iam_policy_change_watch.tf
│       ├── security_hub/               # Phase 5: Security Hub
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── lake/                        # Standalone Lake module
│           └── cloud_trail_lake.tf
├── scripts/
│   ├── assume-audit-role.sh             # STS AssumeRole helper
│   └── test-audit-role-scope.sh         # Permission boundary test
├── diagrams/
│   └── cloud-security-architecture.drawio
└── README.md
```

## Prerequisites

<!-- AWS account, Terraform version, CLI tools needed -->

## Quick Start

```bash
cd setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Phases

### Phase 1: IAM Foundation

<!-- What was built, key decisions, link to module -->

### Phase 2: Cross-Account STS

<!-- Trust policy design, AssumeRole script usage -->

### Phase 3: CloudTrail — API Audit Logging

<!-- Trail config, S3 encryption, log validation -->

### Phase 4: CloudTrail Lake — SQL Analytics

<!-- Event data store, saved queries -->

### Phase 5: Security Hub — Compliance Dashboard

<!-- Standards enabled, findings categories -->

### Phase 6: CloudWatch Alerting Pipeline

<!-- Metric filters, alarms, SNS notifications -->

## Security Controls Summary

| Control | Implementation | Status |
|---------|---------------|--------|
| Least-privilege IAM | | |
| MFA enforcement | | |
| Password policy | | |
| Encrypted audit logs | | |
| Multi-region trail | | |
| Real-time alerting | | |
| Compliance benchmarks | | |
| Temporary credentials | | |

## Cost Estimate

| Service | Estimated Monthly Cost |
|---------|----------------------|
| CloudTrail (1 trail) | |
| CloudTrail Lake (7-day) | |
| Security Hub | |
| CloudWatch Logs | |
| S3 storage | |
| SNS | |
| **Total** | |

## Interview Talking Points

### 1. Why least-privilege matters and how you enforced it

<!-- -->

### 2. How you detect and respond to unauthorized access in real-time

<!-- -->

### 3. How STS enables secure cross-account access without long-lived credentials

<!-- -->

## Lessons Learned

<!-- -->

## Future Improvements

<!-- -->

## License

<!-- -->
