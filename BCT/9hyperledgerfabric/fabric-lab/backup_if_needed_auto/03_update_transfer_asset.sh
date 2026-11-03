#!/usr/bin/env bash
# TASK 3 - Update, then transfer the asset, and verify the changed ledger / world state.
# Usage: bash backup_if_needed_auto/03_update_transfer_asset.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env; require_network
NEW_OWNER="${NEW_OWNER:-Priya}"

banner "TASK 3: Update and transfer asset $ASSET_ID"
asset_exists "$ASSET_ID" || fail "$ASSET_ID does not exist. Run backup_if_needed_auto/02_create_query_asset.sh first."

step "BEFORE - world state of $ASSET_ID"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty
H_BEFORE=$(ledger_height); echo "Ledger height (blocks): $H_BEFORE"

step "UPDATE: UpdateAsset(id=$ASSET_ID, color=green, size=25, owner=Tomoko, appraisedValue=750)"
invoke_cc "{\"function\":\"UpdateAsset\",\"Args\":[\"$ASSET_ID\",\"green\",\"25\",\"Tomoko\",\"750\"]}" both
sleep 3
step "AFTER UPDATE"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty

step "TRANSFER: TransferAsset(id=$ASSET_ID, newOwner=$NEW_OWNER)"
invoke_cc "{\"function\":\"TransferAsset\",\"Args\":[\"$ASSET_ID\",\"$NEW_OWNER\"]}" both
sleep 3
step "AFTER TRANSFER - world state (current value)"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty
OWNER=$(query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | jq -r .Owner)
[ "$OWNER" = "$NEW_OWNER" ] && echo "${C_GREEN}VERIFIED: owner is now $OWNER${C_OFF}" || fail "Owner is $OWNER, expected $NEW_OWNER"

H_AFTER=$(ledger_height)
step "LEDGER verification: height $H_BEFORE -> $H_AFTER  (each successful invoke = 1 new block in the test network)"
H_LAST=$((H_AFTER-1))
step "Blocks that recorded these changes (the immutable history: who, what, endorsed by whom, valid?)"
for ((b=H_BEFORE; b<=H_LAST; b++)); do
  bash "$(dirname "${BASH_SOURCE[0]}")/inspect_block.sh" "$b"
done

step "World state of all assets"
query_cc '{"function":"GetAllAssets","Args":[]}' | pretty
echo; echo "${C_GREEN}TASK 3 COMPLETE.${C_OFF}"
