#!/usr/bin/env bash
# Runs Tasks 1-4 in order. Add PAUSE=1 to wait for ENTER between tasks (useful in the viva).
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for s in 01_start_network 02_create_query_asset 03_update_transfer_asset 04_transaction_flow_demo 05_policy_troubleshoot; do
  bash "$D/$s.sh"
  [ "${PAUSE:-0}" = "1" ] && read -r -p "--- press ENTER for next task ---" _
done
echo "ALL TASKS FINISHED"
