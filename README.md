# Cloud Security & Compliance Monitoring Platform

![Terraform](https://img.shields.io/badge/Terraform-1.12-844FBA?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)
![Security](https://img.shields.io/badge/Security-Trivy_%7C_Checkov-00C853)
![License](https://img.shields.io/badge/License-MIT-blue)

> End-to-end AWS security monitoring -- from IAM hardening to real-time threat detection -- deployed as infrastructure-as-code.

## Architecture

![Architecture Diagram](diagrams/cloud-security-architecture.drawio.png)

## What this does

Most AWS accounts have CloudTrail turned on and nothing watching it. This project closes that gap.

It's a full security monitoring stack in Terraform: IAM lockdown with enforced MFA, multi-region CloudTrail logging encrypted with KMS, SQL-based threat hunting via CloudTrail Lake, compliance scoring through Security Hub (CIS + FSBP), and a CloudWatch-to-SNS alerting pipeline that emails you when something suspicious happens.

I deployed this on a real AWS account, ran attack simulations against it, and queried the results to prove the detection pipeline works end to end.

## What's included

| Layer | What it does |
|-------|-------------|
| **IAM** | Users, groups, scoped policies, MFA enforcement, password policy |
| **STS** | Cross-account AssumeRole with ExternalId, 1-hour temp credentials |
| **CloudTrail** | Multi-region trail, KMS-encrypted S3 logs, log file validation |
| **CloudTrail Lake** | Event data store + 10 SQL threat hunting queries |
| **Security Hub** | FSBP v1.0.0 + CIS v1.4.0 compliance benchmarks |
| **CloudWatch** | Metric filters + alarms for 4 threat patterns -> SNS email |
| **CI/CD** | GitHub Actions: fmt, validate, TFLint, Trivy, Checkov, terraform-docs |

## Project Structure

```
.
├── setup/
│   ├── main.tf                          # Root module -- wires all modules together
│   ├── variables.tf                     # Root input variables
│   ├── outputs.tf                       # Root outputs
│   ├── terraform.tfvars.example         # Example variable values
│   └── modules/
│       ├── iam/                         # Phase 1 + 2: IAM Foundation & STS
│       │   ├── create_users.tf
│       │   ├── manage_group.tf
│       │   ├── enforce_password.tf
│       │   ├── enforce_mfa.tf
│       │   ├── allow_security_audit.tf
│       │   ├── allow_incident_response.tf
│       │   ├── allow_dev_readonly.tf
│       │   └── assume_audit_role.tf
│       ├── cloudTrail/                  # Phase 3 + 4 + 6: Trail, Lake, Alerts
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
│       │   └── main.tf
│       └── lake/                        # Standalone Lake module
│           └── cloud_trail_lake.tf
├── scripts/
│   ├── test-infrastructure.sh           # Infrastructure validation (7 sections)
│   ├── simulate_unauthorized_api.sh     # Attack simulation: AccessDenied events
│   ├── simulate_multiregion_attack.sh   # Attack simulation: multi-region probing
│   ├── simulate_iam_change.sh           # Attack simulation: IAM policy changes
│   ├── simulate_secrets_access.sh       # Attack simulation: Secrets Manager/KMS
│   ├── simulate_s3_tampering.sh         # Attack simulation: S3 bucket operations
│   └── simulate_all.sh                 # Run all simulations
├── queries/
│   └── main.sql                        # 10 CloudTrail Lake SQL queries
├── diagrams/
│   └── cloud-security-architecture.drawio
└── README.md
```

## Prerequisites

- AWS account with admin access
- Terraform >= 1.12.0
- AWS CLI v2, configured with credentials
- An email address for SNS alert subscriptions (you'll need to confirm it)

## Quick start

```bash
cd setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Phases

### Phase 1: IAM foundation

Three IAM users (alice, bob, charlie) in a `cloud_admin` group. Each user gets a login profile but zero standing permissions beyond what the group provides. The group gets three scoped policies:

- **SecurityAudit** -- read-only access to CloudTrail, Security Hub, S3 logs, and IAM
- **IncidentResponse** -- can isolate EC2 instances and revoke IAM sessions during incidents
- **DevReadOnly** -- read access to EC2, S3, RDS, Lambda for day-to-day work

Password policy enforces 14+ characters, symbol/number/case requirements, 90-day rotation, and blocks the last 24 passwords. A separate MFA policy denies all API calls (except MFA self-service) if MFA isn't active on the session.

### Phase 2: Cross-account STS

A `SecurityAuditRole` with a trust policy that accepts `sts:AssumeRole` from configurable principals. For single-account setups it trusts the account root. For multi-account, you pass in external account ARNs and an optional `ExternalId`.

The role's inline policy grants read-only access to CloudTrail, Security Hub, and S3 log buckets -- enough to audit, not enough to change anything. Session duration caps at 1 hour by default.

```bash
# Usage
./scripts/assume-audit-role.sh
```

### Phase 3: CloudTrail -- API audit logging

A single multi-region trail (`security-audit-trail`) that captures all management events and S3 data events across every region. Logs go to a dedicated S3 bucket with:

- KMS encryption (customer-managed key with auto-rotation)
- Log file validation enabled (detects tampering)
- 90-day lifecycle to Glacier, 365-day expiration
- Versioning on, MFA delete off (would lock you out in dev)
- Access logging to a separate bucket with SSE-S3

The KMS key policy is probably the most complex piece in this project. It grants encrypt permissions to CloudTrail, CloudWatch Logs, SNS, and CloudTrail Lake -- each with appropriate conditions so services can only use the key for their intended purpose.

### Phase 4: CloudTrail Lake -- SQL analytics

An event data store (`security-audit-trail-lake-eds`) that ingests management events from all regions. Retention is 7 days (the free tier minimum -- Lake charges $2.50/GB ingested, so keep this short for dev).

Ten pre-built SQL queries in `queries/main.sql` cover the common threat hunting scenarios:

1. Unauthorized API calls (AccessDenied/UnauthorizedAccess)
2. Multi-region error correlation
3. IAM policy modifications
4. Root account activity
5. Console login tracking
6. Secrets Manager and KMS access attempts
7. S3 bucket-level operations
8. Error frequency by service (aggregated)
9. Top callers with failed API calls
10. Suspicious source IPs (high failure count across regions)

### Phase 5: Security Hub -- compliance dashboard

Security Hub with two standards enabled:

- **AWS Foundational Security Best Practices v1.0.0** -- covers ~200 controls across 30+ services
- **CIS AWS Foundations Benchmark v1.4.0** -- the industry-standard checklist

Both are togglable via variables. Security Hub automatically pulls findings from CloudTrail, IAM Access Analyzer, and other integrated services. No extra configuration needed after enabling.

### Phase 6: CloudWatch alerting pipeline

Four CloudWatch metric filters watch the CloudTrail log group for specific patterns:

| Metric filter | Pattern | What it catches |
|---|---|---|
| UnauthorizedAPICalls | `errorCode = AccessDenied \|\| UnauthorizedAccess` | Permission errors anywhere in the account |
| RootAccountUsage | `userIdentity.type = Root` | Any root account activity |
| ConsoleSignInFailures | `eventName = ConsoleLogin && errorMessage = "Failed authentication"` | Brute-force login attempts |
| IAMPolicyChanges | `eventName = Put*Policy \|\| Attach*Policy \|\| Detach*Policy` | Policy modifications |

Each filter feeds a CloudWatch alarm (5-minute evaluation, threshold of 1). Alarms fire to an SNS topic that sends email notifications. The SNS topic is KMS-encrypted and has a resource policy allowing CloudTrail to publish directly.

## Security controls summary

| Control | Implementation | Status |
|---------|---------------|--------|
| Least-privilege IAM | Scoped policies per role (audit, incident, dev) | Done |
| MFA enforcement | Deny-all policy unless `aws:MultiFactorAuthPresent` is true | Done |
| Password policy | 14 chars, 90-day rotation, 24 password memory | Done |
| Encrypted audit logs | KMS CMK with key rotation, per-service grant conditions | Done |
| Multi-region trail | Single trail, `is_multi_region_trail = true` | Done |
| Real-time alerting | CloudWatch metric filters -> alarms -> SNS email | Done |
| Compliance benchmarks | Security Hub FSBP + CIS 1.4.0 | Done |
| Temporary credentials | STS AssumeRole with ExternalId, 1-hour sessions | Done |

## Cost estimate

| Service | Estimated monthly cost |
|---------|----------------------|
| CloudTrail (1 trail, management events) | Free |
| CloudTrail Lake (7-day retention) | ~$2.50/GB ingested |
| Security Hub | ~$0.0010/finding/month |
| CloudWatch Logs | ~$0.50/GB ingested |
| S3 storage | ~$0.023/GB (Standard), less after Glacier transition |
| SNS | Free tier (first 1K emails) |
| KMS | $1/key/month + $0.03/10K requests |
| **Total (low-traffic dev account)** | **~$5-15/month** |

## Testing

### Infrastructure validation

```bash
./scripts/test-infrastructure.sh
```

Tests 7 areas: IAM users/groups/policies, STS AssumeRole, CloudTrail status, S3 bucket configuration, CloudWatch alarms, SNS subscriptions, Security Hub standards, and CloudTrail Lake.

### Attack simulation

```bash
# Run all simulations
./scripts/simulate_all.sh

# Or individually
./scripts/simulate_unauthorized_api.sh    # Generates AccessDenied events
./scripts/simulate_multiregion_attack.sh  # Probes multiple regions
./scripts/simulate_iam_change.sh          # Attempts IAM policy changes
./scripts/simulate_secrets_access.sh      # Tries to read nonexistent secrets
./scripts/simulate_s3_tampering.sh        # Attempts S3 bucket operations
```

After running simulations, wait 5-10 minutes for events to appear in CloudTrail Lake, then run the queries from `queries/main.sql`.

### CI pipeline

GitHub Actions runs on every push to `main` that touches `setup/`:

1. `terraform fmt -recursive -check` -- formatting
2. `terraform validate` -- syntax and provider validation
3. TFLint -- linting with `--recursive` across all modules
4. Trivy -- IaC security scan (CRITICAL + HIGH)
5. Checkov -- policy-as-code compliance checks
6. terraform-docs -- documentation drift detection

## Key Points

<details>
<summary><b>1. Why least-privilege matters and how you enforced it</b></summary>

Every IAM user starts with zero permissions. The admin group grants three scoped policies -- SecurityAudit (read-only logs), IncidentResponse (isolate instances, revoke sessions), and DevReadOnly (read EC2/S3/RDS/Lambda). No policy uses `*` for actions. MFA is enforced at the IAM level: a deny-all policy blocks every API call unless the session has MFA. Even if credentials leak, they're useless without the second factor.

The cross-account audit role is read-only by design. It can look at CloudTrail events and Security Hub findings, but it can't modify anything. Session duration is capped at 1 hour.
</details>

<details>
<summary><b>2. How you detect and respond to unauthorized access in real-time</b></summary>

CloudTrail captures every API call across all regions. CloudWatch metric filters watch the log stream for specific patterns -- AccessDenied errors, root account usage, failed console logins, IAM policy changes. When a filter matches, it increments a custom metric. A CloudWatch alarm evaluates every 5 minutes, and if the count hits 1, it fires an SNS notification to the security team's email.

For deeper investigation, CloudTrail Lake stores events in a queryable format. I wrote 10 SQL queries that cover common threat hunting scenarios -- from "show me all AccessDenied events in the last 24 hours" to "which source IP has the most failed calls across the most regions" (a good indicator of automated scanning).
</details>

<details>
<summary><b>3. How STS enables secure cross-account access without long-lived credentials</b></summary>

Instead of creating IAM users in every account, you create one IAM role with a trust policy. The trust policy specifies which external accounts can assume the role. An ExternalId prevents confused deputy attacks -- the caller must know the secret ID.

The credentials from `sts:AssumeRole` are temporary. They expire after 1 hour. No access keys stored anywhere, no credentials in config files. Assume the role, do the audit, credentials self-destruct.
</details>

## Lessons learned

- KMS key policies are the hardest part of this whole stack. CloudTrail Lake needs `kms:CreateGrant` without conditions, but CloudTrail logging needs `kms:GenerateDataKey*` with a source ARN condition. Getting these to coexist on the same key took multiple iterations.
- S3 bucket names are globally unique. `org-cloudtrail-logs` was already taken by someone else. Use your account ID as a suffix.
- New S3 buckets have ACLs disabled by default (since April 2023). Don't use `aws_s3_bucket_acl` -- it will fail.
- CloudTrail Lake event data stores that are in `PENDING_DELETION` still block the name. If you need to recreate, change the name.
- SNS topics need an explicit resource policy for CloudTrail to publish to them. The KMS key also needs to allow `cloudtrail.amazonaws.com` as a principal for SNS encryption.
- `set -euo pipefail` in bash test scripts will exit on the first non-zero return -- including arithmetic expressions like `((PASS++))` when PASS is 0. Use `PASS=$((PASS + 1))` instead, or drop `set -e`.

## Future improvements

- GuardDuty integration for ML-based threat detection
- AWS Config rules for continuous resource compliance monitoring
- Lambda-based auto-remediation (e.g., auto-revoke public S3 bucket policies)
- Multi-account setup with AWS Organizations and delegated admin for Security Hub
- Terraform state stored in S3 with DynamoDB locking (currently local)
- Slack/PagerDuty integration instead of email-only SNS notifications
- Dashboard in Grafana or QuickSight for CloudTrail Lake query results

## Author

Swan Htet Aung Phyo

## License

MIT
