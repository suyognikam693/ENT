#!/usr/bin/env bash
# TASK 2 - Create / query a supplied asset using the chaincode via the peer CLI.
# Usage: bash backup_if_needed_auto/02_create_query_asset.sh
#        ASSET_ID=asset9 bash backup_if_needed_auto/02_create_query_asset.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env; require_network

banner "TASK 2: Create and query an asset  (asset id = $ASSET_ID)"

step "Query the world state first: GetAllAssets (read-only, no ordering)"
query_cc '{"function":"GetAllAssets","Args":[]}' | pretty

step "Is '$ASSET_ID' already on the ledger?  (AssetExists)"
if asset_exists "$ASSET_ID"; then
  note "'$ASSET_ID' already exists (script was run before). Skipping creation. Use ASSET_ID=assetNN for a fresh one."
else
  step "Seed ledger with the sample assets? (InitLedger - only if the ledger is empty)"
  if [ "$(query_cc '{"function":"GetAllAssets","Args":[]}' | jq 'length')" = "0" ]; then
    invoke_cc '{"function":"InitLedger","Args":[]}' both
    sleep 3
  else
    note "Ledger already contains assets - InitLedger not needed."
  fi
  step "CREATE: CreateAsset(id=$ASSET_ID, color=blue, size=20, owner=Tomoko, appraisedValue=500)"
  H0=$(ledger_height)
  invoke_cc "{\"function\":\"CreateAsset\",\"Args\":[\"$ASSET_ID\",\"blue\",\"20\",\"Tomoko\",\"500\"]}" both
  sleep 3
  H1=$(ledger_height)
  echo "Ledger height before=$H0 after=$H1  (a new block was committed)"
fi

step "QUERY: ReadAsset($ASSET_ID)"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty

step "QUERY: GetAllAssets (now includes $ASSET_ID)"
query_cc '{"function":"GetAllAssets","Args":[]}' | pretty

echo; echo "${C_GREEN}TASK 2 COMPLETE.${C_OFF}"
