#!/usr/bin/env bash
set +e

echo "=== Simulating IAM Policy Changes ==="

POLICY_ARN=$(aws iam create-policy \
  --policy-name demo-overprivileged-policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}' \
  --query 'Policy.Arn' --output text 2>&1)

if echo "$POLICY_ARN" | grep -q "arn:aws"; then
  echo "Created policy: $POLICY_ARN"
  aws iam delete-policy --policy-arn "$POLICY_ARN" 2>&1 || true
  echo "Deleted policy: $POLICY_ARN"
else
  echo "Policy creation failed (expected if already exists)"
fi

aws iam create-role --role-name backdoor-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"*"},"Action":"sts:AssumeRole"}]}' 2>&1 || true

aws iam delete-role --role-name backdoor-role 2>&1 || true

echo "=== Done: IAM policy and role changes recorded ==="
