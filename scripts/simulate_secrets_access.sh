#!/usr/bin/env bash
set +e

REGION="${AWS_DEFAULT_REGION:-eu-central-1}"

echo "=== Simulating Secrets & KMS Access Attempts ==="

aws secretsmanager get-secret-value --secret-id production-credentials --region "$REGION" 2>&1 || true
aws secretsmanager get-secret-value --secret-id api-keys --region "$REGION" 2>&1 || true
aws secretsmanager get-secret-value --secret-id database-password --region "$REGION" 2>&1 || true
aws kms decrypt --ciphertext-blob fileb:///dev/null --region "$REGION" 2>&1 || true
aws kms disable-key --key-id 00000000-0000-0000-0000-000000000000 --region "$REGION" 2>&1 || true

echo "=== Done: 5 secrets/KMS access attempts ==="
