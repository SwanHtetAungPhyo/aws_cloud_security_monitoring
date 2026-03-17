#!/usr/bin/env bash
set +e

echo "=== Simulating Multi-Region Attack ==="

aws ec2 run-instances --image-id ami-fake --instance-type t2.micro --region us-east-1 2>&1 || true
aws ec2 run-instances --image-id ami-fake --instance-type t2.micro --region ap-southeast-1 2>&1 || true
aws ec2 run-instances --image-id ami-fake --instance-type t2.micro --region eu-west-1 2>&1 || true
aws ec2 run-instances --image-id ami-fake --instance-type t2.micro --region sa-east-1 2>&1 || true
aws lambda invoke --function-name steal-data /tmp/out --region us-west-2 2>&1 || true
aws secretsmanager get-secret-value --secret-id prod-db-password --region ap-northeast-1 2>&1 || true
aws dynamodb delete-table --table-name users --region eu-north-1 2>&1 || true

echo "=== Done: 7 regions targeted ==="
