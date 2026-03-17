#!/usr/bin/env bash
set +e

REGION="${AWS_DEFAULT_REGION:-eu-central-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/SecurityAuditRole"
BUCKET=$(aws cloudtrail describe-trails --query 'trailList[0].S3BucketName' --output text --region "$REGION" 2>/dev/null || echo "your-cloudtrail-bucket")

echo "=== Simulating Unauthorized API Calls ==="

CREDS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name demo-attacker \
  --region "$REGION")

export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['AccessKeyId'])")
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SecretAccessKey'])")
export AWS_SESSION_TOKEN=$(echo "$CREDS" | python3 -c "import sys,json; print(json.load(sys.stdin)['Credentials']['SessionToken'])")

aws iam create-user --user-name hacker --region "$REGION" 2>&1 || true
aws iam delete-user --user-name alice --region "$REGION" 2>&1 || true
aws ec2 run-instances --image-id ami-fake --instance-type t2.micro --region "$REGION" 2>&1 || true
aws ec2 terminate-instances --instance-ids i-00000000000000000 --region "$REGION" 2>&1 || true
aws s3 rb "s3://${BUCKET}" --region "$REGION" 2>&1 || true
aws rds delete-db-instance --db-instance-identifier production-db --region "$REGION" 2>&1 || true
aws lambda delete-function --function-name critical-function --region "$REGION" 2>&1 || true

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

echo "=== Done: 7 unauthorized actions attempted ==="
