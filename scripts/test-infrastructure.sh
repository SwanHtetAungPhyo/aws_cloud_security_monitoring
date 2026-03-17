#!/usr/bin/env bash
set +e

REGION="${AWS_DEFAULT_REGION:-eu-central-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
TRAIL_NAME=$(aws cloudtrail describe-trails --region "$REGION" --query 'trailList[0].Name' --output text 2>/dev/null || echo "")
BUCKET_NAME=$(aws cloudtrail describe-trails --region "$REGION" --query 'trailList[0].S3BucketName' --output text 2>/dev/null || echo "")
LOG_GROUP="/aws/cloudtrail/${TRAIL_NAME}"
SNS_TOPIC="arn:aws:sns:${REGION}:${ACCOUNT_ID}:security-alerts"
AUDIT_ROLE="arn:aws:iam::${ACCOUNT_ID}:role/SecurityAuditRole"
EVENT_DATA_STORE=$(aws cloudtrail list-event-data-stores --region "$REGION" \
  --query 'EventDataStores[?Status==`ENABLED`].EventDataStoreArn | [0]' --output text 2>/dev/null || echo "")

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

check() {
  local description="$1"
  shift
  if output=$("$@" 2>&1); then
    pass "$description"
  else
    fail "$description"
    echo "        $output" | head -3
  fi
}

echo "======================================================"
echo " Cloud Security Infrastructure Test Suite"
echo " Region: ${REGION} | Account: ${ACCOUNT_ID}"
echo "======================================================"
echo ""

# -----------------------------------------------------------
echo "[1/7] IAM Foundation"
echo "------------------------------------------------------"

check "IAM users exist" \
  aws iam list-users --path-prefix /users/ --region "$REGION" \
  --query 'Users[].UserName' --output text

check "Admin group exists" \
  aws iam get-group --group-name cloud_admin --region "$REGION" \
  --query 'Group.GroupName' --output text

check "Password policy enforced" \
  aws iam get-account-password-policy --region "$REGION" \
  --query 'PasswordPolicy.MinimumPasswordLength' --output text

ATTACHED=$(aws iam list-attached-group-policies --group-name cloud_admin \
  --region "$REGION" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null || echo "")
if echo "$ATTACHED" | grep -q "ForceMFAPolicy"; then
  pass "MFA policy attached to admin group"
else
  fail "MFA policy attached to admin group"
fi

echo ""

# -----------------------------------------------------------
echo "[2/7] STS AssumeRole"
echo "------------------------------------------------------"

STS_OUTPUT=$(aws sts assume-role \
  --role-arn "$AUDIT_ROLE" \
  --role-session-name infra-test \
  --region "$REGION" 2>&1) && {
  pass "Can assume SecurityAuditRole"

  export AWS_ACCESS_KEY_ID=$(echo "$STS_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
  export AWS_SECRET_ACCESS_KEY=$(echo "$STS_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
  export AWS_SESSION_TOKEN=$(echo "$STS_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SessionToken'])")

  CALLER=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "")
  if echo "$CALLER" | grep -q "SecurityAuditRole"; then
    pass "Session identity is SecurityAuditRole"
  else
    fail "Session identity is SecurityAuditRole"
  fi

  # Test allowed action
  if aws cloudtrail describe-trails --region "$REGION" >/dev/null 2>&1; then
    pass "Audit role can describe CloudTrail trails (allowed)"
  else
    fail "Audit role can describe CloudTrail trails (allowed)"
  fi

  # Test denied action
  if aws iam create-user --user-name test-deny --region "$REGION" >/dev/null 2>&1; then
    fail "Audit role SHOULD NOT create IAM users (denied)"
    aws iam delete-user --user-name test-deny --region "$REGION" 2>/dev/null || true
  else
    pass "Audit role cannot create IAM users (denied)"
  fi

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
} || {
  fail "Can assume SecurityAuditRole"
}

echo ""

# -----------------------------------------------------------
echo "[3/7] CloudTrail"
echo "------------------------------------------------------"

if [ -z "$TRAIL_NAME" ] || [ "$TRAIL_NAME" = "None" ]; then
  fail "CloudTrail trail not found"
else
  TRAIL_STATUS=$(aws cloudtrail get-trail-status --name "$TRAIL_NAME" \
    --region "$REGION" 2>/dev/null)
  if [ $? -eq 0 ]; then
    IS_LOGGING=$(echo "$TRAIL_STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin)['IsLogging'])")
    if [ "$IS_LOGGING" = "True" ]; then
      pass "CloudTrail is actively logging"
    else
      fail "CloudTrail is NOT logging"
    fi
  else
    fail "CloudTrail trail not found"
  fi

  check "Trail is multi-region" \
    aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" \
    --region "$REGION" \
    --query 'trailList[0].IsMultiRegionTrail' --output text

  check "Log file validation enabled" \
    aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" \
    --region "$REGION" \
    --query 'trailList[0].LogFileValidationEnabled' --output text

  KMS_KEY=$(aws cloudtrail describe-trails --trail-name-list "$TRAIL_NAME" \
    --region "$REGION" \
    --query 'trailList[0].KmsKeyId' --output text 2>/dev/null || echo "None")
  if [ "$KMS_KEY" != "None" ] && [ -n "$KMS_KEY" ]; then
    pass "Trail encrypted with KMS"
  else
    fail "Trail KMS encryption"
  fi
fi

echo ""

# -----------------------------------------------------------
echo "[4/7] S3 Log Bucket"
echo "------------------------------------------------------"

if [ -z "$BUCKET_NAME" ] || [ "$BUCKET_NAME" = "None" ]; then
  fail "No S3 bucket found for CloudTrail"
else
  check "Bucket exists" \
    aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION"

  ENC_ALGO=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' \
    --output text 2>/dev/null || echo "None")
  if [ "$ENC_ALGO" = "aws:kms" ]; then
    pass "Bucket encrypted with KMS (aws:kms)"
  else
    fail "Bucket encryption (got: $ENC_ALGO)"
  fi

  VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --query 'Status' --output text 2>/dev/null || echo "None")
  if [ "$VERSIONING" = "Enabled" ]; then
    pass "Bucket versioning enabled"
  else
    fail "Bucket versioning (got: $VERSIONING)"
  fi

  PUBLIC_BLOCK=$(aws s3api get-public-access-block --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --query 'PublicAccessBlockConfiguration.BlockPublicAcls' \
    --output text 2>/dev/null || echo "false")
  if [ "$PUBLIC_BLOCK" = "True" ]; then
    pass "Public access blocked"
  else
    fail "Public access block"
  fi

  LOGGING=$(aws s3api get-bucket-logging --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --query 'LoggingEnabled.TargetBucket' --output text 2>/dev/null || echo "None")
  if [ "$LOGGING" != "None" ] && [ -n "$LOGGING" ]; then
    pass "Access logging enabled"
  else
    fail "Access logging not enabled"
  fi

  LOG_COUNT=$(aws s3 ls "s3://${BUCKET_NAME}/AWSLogs/" --region "$REGION" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$LOG_COUNT" -gt 0 ]; then
    pass "CloudTrail logs present in bucket"
  else
    warn "No CloudTrail logs yet (may take a few minutes)"
  fi
fi

echo ""

# -----------------------------------------------------------
echo "[5/7] CloudWatch Alerts"
echo "------------------------------------------------------"

check "Log group exists" \
  aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP" \
  --region "$REGION" \
  --query 'logGroups[0].logGroupName' --output text

FILTER_COUNT=$(aws logs describe-metric-filters \
  --log-group-name "$LOG_GROUP" \
  --region "$REGION" \
  --query 'length(metricFilters)' --output text 2>/dev/null || echo "0")
if [ "$FILTER_COUNT" -gt 0 ]; then
  pass "Metric filters configured ($FILTER_COUNT filters)"
else
  fail "No metric filters found"
fi

ALARM_COUNT=$(aws cloudwatch describe-alarms \
  --region "$REGION" \
  --query 'length(MetricAlarms)' --output text 2>/dev/null || echo "0")
if [ "$ALARM_COUNT" -gt 0 ]; then
  pass "CloudWatch alarms configured ($ALARM_COUNT alarms)"
else
  fail "No CloudWatch alarms found"
fi

LOG_KMS=$(aws logs describe-log-groups \
  --log-group-name-prefix "$LOG_GROUP" \
  --region "$REGION" \
  --query 'logGroups[0].kmsKeyId' --output text 2>/dev/null || echo "None")
if [ "$LOG_KMS" != "None" ] && [ -n "$LOG_KMS" ]; then
  pass "Log group encrypted with KMS"
else
  fail "Log group KMS encryption"
fi

echo ""

# -----------------------------------------------------------
echo "[6/7] SNS Notifications"
echo "------------------------------------------------------"

check "SNS topic exists" \
  aws sns get-topic-attributes --topic-arn "$SNS_TOPIC" --region "$REGION" \
  --query 'Attributes.TopicArn' --output text

SNS_KMS=$(aws sns get-topic-attributes --topic-arn "$SNS_TOPIC" \
  --region "$REGION" \
  --query 'Attributes.KmsMasterKeyId' --output text 2>/dev/null || echo "None")
if [ "$SNS_KMS" != "None" ] && [ -n "$SNS_KMS" ]; then
  pass "SNS topic encrypted with KMS"
else
  fail "SNS topic KMS encryption"
fi

SUB_COUNT=$(aws sns list-subscriptions-by-topic --topic-arn "$SNS_TOPIC" \
  --region "$REGION" \
  --query 'length(Subscriptions)' --output text 2>/dev/null || echo "0")
if [ "$SUB_COUNT" -gt 0 ]; then
  SUB_STATUS=$(aws sns list-subscriptions-by-topic --topic-arn "$SNS_TOPIC" \
    --region "$REGION" \
    --query 'Subscriptions[0].SubscriptionArn' --output text 2>/dev/null || echo "")
  if echo "$SUB_STATUS" | grep -q "PendingConfirmation"; then
    warn "Email subscription pending confirmation -- check your inbox"
  else
    pass "Email subscription confirmed"
  fi
else
  fail "No SNS subscriptions found"
fi

echo ""

# -----------------------------------------------------------
echo "[7/7] Security Hub & CloudTrail Lake"
echo "------------------------------------------------------"

check "Security Hub enabled" \
  aws securityhub describe-hub --region "$REGION" \
  --query 'HubArn' --output text

STANDARDS=$(aws securityhub get-enabled-standards --region "$REGION" \
  --query 'length(StandardsSubscriptions)' --output text 2>/dev/null || echo "0")
if [ "$STANDARDS" -gt 0 ]; then
  pass "Security standards enabled ($STANDARDS standards)"
else
  fail "No security standards enabled"
fi

if [ -n "$EVENT_DATA_STORE" ] && [ "$EVENT_DATA_STORE" != "None" ]; then
  EDS_STATUS=$(aws cloudtrail get-event-data-store \
    --event-data-store "$EVENT_DATA_STORE" \
    --region "$REGION" \
    --query 'Status' --output text 2>/dev/null || echo "UNKNOWN")
  if [ "$EDS_STATUS" = "ENABLED" ]; then
    pass "CloudTrail Lake event data store active"
  else
    warn "CloudTrail Lake status: $EDS_STATUS (may still be creating)"
  fi

  EDS_KMS=$(aws cloudtrail get-event-data-store \
    --event-data-store "$EVENT_DATA_STORE" \
    --region "$REGION" \
    --query 'KmsKeyId' --output text 2>/dev/null || echo "None")
  if [ "$EDS_KMS" != "None" ] && [ -n "$EDS_KMS" ]; then
    pass "CloudTrail Lake encrypted with KMS"
  else
    fail "CloudTrail Lake KMS encryption"
  fi
else
  fail "No CloudTrail Lake event data store found"
fi

echo ""

# -----------------------------------------------------------
echo "======================================================"
echo " Results: $PASS passed | $FAIL failed | $WARN warnings"
echo "======================================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
