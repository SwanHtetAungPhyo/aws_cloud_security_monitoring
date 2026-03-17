#!/usr/bin/env bash
set +e

REGION="${AWS_DEFAULT_REGION:-eu-central-1}"
BUCKET=$(aws cloudtrail describe-trails --query 'trailList[0].S3BucketName' --output text --region "$REGION" 2>/dev/null || echo "your-cloudtrail-bucket")

echo "=== Simulating S3 Bucket Tampering ==="

aws s3api delete-bucket-encryption --bucket "$BUCKET" --region "$REGION" 2>&1 || true
aws s3api put-bucket-acl --bucket "$BUCKET" --acl public-read --region "$REGION" 2>&1 || true
aws s3api delete-bucket-policy --bucket "$BUCKET" --region "$REGION" 2>&1 || true
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false \
  --region "$REGION" 2>&1 || true
aws s3api delete-bucket-versioning --bucket "$BUCKET" --region "$REGION" 2>&1 || true

echo "=== Done: 5 S3 tampering attempts ==="
