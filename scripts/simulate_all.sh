#!/usr/bin/env bash
set +e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "======================================================"
echo " Cloud Security — Full Attack Simulation"
echo "======================================================"
echo ""

"$DIR/simulate_unauthorized_api.sh"
echo ""
"$DIR/simulate_multiregion_attack.sh"
echo ""
"$DIR/simulate_iam_change.sh"
echo ""
"$DIR/simulate_secrets_access.sh"
echo ""
"$DIR/simulate_s3_tampering.sh"
echo ""

echo "======================================================"
echo " All simulations complete."
echo " Wait 15 minutes, then run queries from queries/main.sql"
echo "======================================================"
