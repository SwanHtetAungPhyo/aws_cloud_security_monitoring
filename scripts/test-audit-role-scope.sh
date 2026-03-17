#!/usr/bin/env bash
#
# Tests that the SecurityAuditRole has correct permissions:
# - ALLOWED: CloudTrail, Security Hub, S3 read (audit actions)
# - DENIED:  IAM write, EC2 mutations, anything outside scope
#
# Run this AFTER sourcing assume-audit-role.sh
#

set -euo pipefail

PASS=0
FAIL=0

check_allowed() {
  local desc="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  PASS (allowed): $desc"
    ((PASS++))
  else
    echo "  FAIL (denied but should be allowed): $desc"
    ((FAIL++))
  fi
}

check_denied() {
  local desc="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  FAIL (allowed but should be denied): $desc"
    ((FAIL++))
  else
    echo "  PASS (denied): $desc"
    ((PASS++))
  fi
}

echo "=== Testing SecurityAuditRole Permissions ==="
echo ""

# Verify we're using the assumed role
echo "Current identity:"
aws sts get-caller-identity --output table
echo ""

echo "--- Actions that SHOULD be allowed ---"
check_allowed "cloudtrail:DescribeTrails" aws cloudtrail describe-trails
check_allowed "cloudtrail:ListTrails" aws cloudtrail list-trails
check_allowed "securityhub:DescribeHub" aws securityhub describe-hub
check_allowed "s3:ListBuckets" aws s3api list-buckets

echo ""
echo "--- Actions that SHOULD be denied ---"
check_denied "iam:CreateUser" aws iam create-user --user-name test-should-fail
check_denied "ec2:RunInstances" aws ec2 run-instances --image-id ami-00000000 --instance-type t2.micro
check_denied "s3:CreateBucket" aws s3api create-bucket --bucket test-should-fail-$RANDOM
check_denied "cloudtrail:DeleteTrail" aws cloudtrail delete-trail --name test-should-fail

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [[ $FAIL -gt 0 ]]; then
  echo "Some permission checks failed — review the audit role policy."
  exit 1
fi
