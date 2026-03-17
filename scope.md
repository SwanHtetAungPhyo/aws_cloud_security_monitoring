# Cloud Security & Compliance Monitoring Platform — Project Scope

## Phase 1: AWS Account & IAM Foundation

**Goal:** Establish a secure identity baseline

- [ ] Create a dedicated AWS account (or use an isolated sandbox)
- [ ] Delete root access keys, enable MFA on root account
- [ ] Create an IAM admin group with `AdministratorAccess` (temporary, for setup only)
- [ ] Create individual IAM users — no shared credentials
- [ ] Create custom IAM policies following least-privilege:
  - `SecurityAuditorPolicy` — read-only access to CloudTrail, Security Hub, CloudWatch
  - `IncidentResponderPolicy` — limited write access to isolate resources
  - `DevReadOnlyPolicy` — read-only access to specific services
- [ ] Set up IAM password policy:
  - Minimum 14 characters, require symbols/numbers
  - Password expiration every 90 days
  - Prevent password reuse (last 5)
- [ ] Enable MFA for all IAM users (virtual MFA with Google Authenticator or Authy)

**Deliverable:** IAM policy JSON files, screenshot of MFA enforcement

---

## Phase 2: Cross-Account Access with STS

**Goal:** Simulate a multi-account org with temporary credentials

- [ ] Create a second AWS account (or simulate with a separate IAM role)
- [ ] Create a cross-account IAM role: `SecurityAuditCrossAccountRole`
  - Trust policy allowing Account A to assume the role in Account B
  - Permission policy: read-only CloudTrail + Security Hub
- [ ] Write an `AssumeRole` script using AWS CLI:
  ```bash
  aws sts assume-role \
    --role-arn arn:aws:iam::ACCOUNT_B:role/SecurityAuditCrossAccountRole \
    --role-session-name audit-session
  ```
- [ ] Verify temporary credentials expire correctly (1 hour default)
- [ ] Test that the assumed role cannot exceed its granted permissions

**Deliverable:** Trust policy JSON, AssumeRole CLI script, proof of scoped access

---

## Phase 3: CloudTrail — API Audit Logging

**Goal:** Capture every API call across your account

- [ ] Create an S3 bucket for CloudTrail logs:
  - Enable versioning
  - Enable SSE-S3 or SSE-KMS encryption
  - Block all public access
  - Add bucket policy restricting access to CloudTrail service only
- [ ] Create a CloudTrail trail:
  - Multi-region trail (all regions)
  - Enable management events (read + write)
  - Enable data events for S3 (object-level logging)
  - Enable log file validation (digest files)
- [ ] Verify logs are flowing by making test API calls:
  ```bash
  aws ec2 describe-instances
  aws s3 ls
  ```
- [ ] Check the S3 bucket for log files after ~15 minutes

**Deliverable:** CloudTrail trail config, S3 bucket policy, sample log entries

---

## Phase 4: CloudTrail Lake — Advanced Querying

**Goal:** Run SQL-based queries against your audit logs

- [ ] Create a CloudTrail Lake event data store:
  - Include management events
  - Retention period: 7 days (free tier friendly)
- [ ] Wait for events to populate (~30 minutes)
- [ ] Write and run these queries:

  **Find all console logins:**
  ```sql
  SELECT eventTime, userIdentity.arn, sourceIPAddress
  FROM event_data_store_id
  WHERE eventName = 'ConsoleLogin'
  ORDER BY eventTime DESC
  ```

  **Find all failed API calls:**
  ```sql
  SELECT eventTime, eventName, errorCode, userIdentity.arn
  FROM event_data_store_id
  WHERE errorCode IS NOT NULL
  ORDER BY eventTime DESC
  ```

  **Find who modified IAM policies:**
  ```sql
  SELECT eventTime, eventName, userIdentity.arn, requestParameters
  FROM event_data_store_id
  WHERE eventSource = 'iam.amazonaws.com'
    AND eventName LIKE 'Put%' OR eventName LIKE 'Attach%'
  ```

**Deliverable:** 3+ saved queries with sample output screenshots

---

## Phase 5: AWS Security Hub

**Goal:** Centralized security posture dashboard

- [ ] Enable AWS Security Hub
- [ ] Enable these compliance standards:
  - AWS Foundational Security Best Practices v1.0
  - CIS AWS Foundations Benchmark v1.4.0
- [ ] Wait for initial assessment (~2 hours for full scan)
- [ ] Review findings and categorize:
  - **Critical:** Fix immediately (e.g., root account without MFA, public S3 buckets)
  - **High:** Fix within this project
  - **Medium/Low:** Document as known and accepted
- [ ] Fix at least 5 findings manually:
  - Example: Enable S3 default encryption
  - Example: Enable VPC Flow Logs
  - Example: Remove unused security groups
  - Example: Enable EBS default encryption
  - Example: Restrict overly permissive security group rules
- [ ] Re-run assessment and show improved security score

**Deliverable:** Before/after security score screenshots, list of remediated findings

---

## Phase 6: CloudWatch Alerting Pipeline

**Goal:** Real-time alerts for suspicious activity

- [ ] Create a CloudWatch Log Group: `/aws/cloudtrail/security-alerts`
- [ ] Configure CloudTrail to send logs to this Log Group
- [ ] Create these Metric Filters:

  **Unauthorized API calls:**
  ```
  Filter pattern: { $.errorCode = "AccessDenied" || $.errorCode = "UnauthorizedAccess" }
  Metric: UnauthorizedAPICalls
  ```

  **Root account usage:**
  ```
  Filter pattern: { $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }
  Metric: RootAccountUsage
  ```

  **Console login without MFA:**
  ```
  Filter pattern: { $.eventName = "ConsoleLogin" && $.additionalEventData.MFAUsed = "No" }
  Metric: ConsoleLoginWithoutMFA
  ```

  **IAM policy changes:**
  ```
  Filter pattern: { $.eventName = "DeleteGroupPolicy" || $.eventName = "DeleteRolePolicy" || $.eventName = "PutGroupPolicy" || $.eventName = "PutRolePolicy" || $.eventName = "AttachRolePolicy" || $.eventName = "DetachRolePolicy" }
  Metric: IAMPolicyChanges
  ```

- [ ] Create CloudWatch Alarms for each metric (threshold >= 1)
- [ ] Create an SNS topic: `security-alerts`
- [ ] Subscribe your email to the SNS topic
- [ ] Connect each alarm to the SNS topic
- [ ] **Test it:** Deliberately trigger each alarm:
  - Try an API call with insufficient permissions
  - Log in without MFA (create a test user without MFA)
  - Modify an IAM policy
- [ ] Verify you receive email alerts

**Deliverable:** Metric filter patterns, alarm configs, screenshot of email alerts received

---

## Phase 7: Documentation & Architecture Diagram

**Goal:** Make it resume and interview-ready

- [ ] Draw an architecture diagram showing:
  ```
  API Calls --> CloudTrail --> S3 (encrypted logs)
                    |
              CloudTrail Lake (SQL queries)
                    |
              CloudWatch Logs --> Metric Filters --> Alarms --> SNS --> Email
                    |
              Security Hub (compliance dashboard)
                    |
              IAM (least-privilege) <--> STS (cross-account)
  ```
- [ ] Create a GitHub repo with:
  - `/iam-policies/` — all custom policy JSON files
  - `/cloudtrail-lake-queries/` — saved SQL queries
  - `/cloudwatch-filters/` — metric filter patterns
  - `/scripts/` — AssumeRole script, any automation
  - `README.md` — project overview, architecture diagram, what you learned
- [ ] Write 3 "interview-ready" talking points:
  1. Why least-privilege matters and how you enforced it
  2. How you detect and respond to unauthorized access in real-time
  3. How STS enables secure cross-account access without long-lived credentials

**Deliverable:** GitHub repo, architecture diagram, talking points

---

## Estimated Cost

| Service | Estimated Cost |
|---|---|
| CloudTrail (1 trail) | Free (first trail) |
| CloudTrail Lake (7-day retention) | ~$2-5 |
| Security Hub | ~$1-3 (free 30-day trial) |
| CloudWatch Logs | ~$0.50-1 |
| S3 storage | < $0.10 |
| SNS | Free tier |
| **Total** | **~$5-10** |

---

## Timeline

| Phase | Time |
|---|---|
| Phase 1: IAM Foundation | Day 1 |
| Phase 2: STS Cross-Account | Day 1 |
| Phase 3: CloudTrail Setup | Day 2 |
| Phase 4: CloudTrail Lake | Day 2 |
| Phase 5: Security Hub | Day 3 |
| Phase 6: CloudWatch Alerts | Day 3-4 |
| Phase 7: Docs & Diagram | Day 4-5 |

**You can finish this in one weekend if you go hard.**
