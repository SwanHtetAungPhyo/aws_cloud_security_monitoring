#!/usr/bin/env bash
#
# Assumes the SecurityAuditRole and exports temporary credentials.
# Usage:
#   source ./assume-audit-role.sh <ACCOUNT_ID> [EXTERNAL_ID]
#
# Example (same-account):
#   source ./assume-audit-role.sh 123456789012
#
# Example (cross-account with external ID):
#   source ./assume-audit-role.sh 987654321098 my-external-id
#

set -euo pipefail

ACCOUNT_ID="${1:?Usage: source ./assume-audit-role.sh <ACCOUNT_ID> [EXTERNAL_ID]}"
EXTERNAL_ID="${2:-}"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/SecurityAuditRole"
SESSION_NAME="audit-session-$(date +%s)"

echo "Assuming role: ${ROLE_ARN}"
echo "Session name:  ${SESSION_NAME}"

ASSUME_CMD=(
  aws sts assume-role
  --role-arn "$ROLE_ARN"
  --role-session-name "$SESSION_NAME"
  --duration-seconds 3600
  --output json
)

if [[ -n "$EXTERNAL_ID" ]]; then
  ASSUME_CMD+=(--external-id "$EXTERNAL_ID")
  echo "External ID:   ${EXTERNAL_ID}"
fi

CREDENTIALS=$("${ASSUME_CMD[@]}")

export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')

EXPIRATION=$(echo "$CREDENTIALS" | jq -r '.Credentials.Expiration')

echo ""
echo "Temporary credentials exported successfully."
echo "Expiration: ${EXPIRATION}"
echo ""
echo "Verify with:"
echo "  aws sts get-caller-identity"
