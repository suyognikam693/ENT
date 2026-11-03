#!/usr/bin/env bash
# TASK 4b - Troubleshoot a small transaction / endorsement-policy issue.
# Shows: tx endorsed by only ONE org violates the "majority" lifecycle policy
#        -> tx is ordered into a block but flagged ENDORSEMENT_POLICY_FAILURE and NOT applied.
# Then fixes it by collecting both endorsements.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env; require_network
HERE="$(dirname "${BASH_SOURCE[0]}")"

banner "TASK 4b: Endorsement-policy troubleshooting"
asset_exists "$ASSET_ID" || fail "$ASSET_ID missing - run backup_if_needed_auto/02_create_query_asset.sh"

step "Step 1 - what is the endorsement policy of chaincode '$CC_NAME'?"
set_org1
peer lifecycle chaincode querycommitted -C "$CHANNEL" -n "$CC_NAME" 2>&1
note "No explicit signature policy => default = channel's LifecycleEndorsement policy = MAJORITY of channel orgs."
note "With 2 orgs, majority = 2  -> BOTH Org1 and Org2 must endorse."

OWNER_NOW=$(query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | jq -r .Owner)
VAL_NOW=$(query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | jq -r .AppraisedValue)
step "Step 2 - FAULTY invoke: endorse ONLY with Org1  (try to set appraisedValue=99999)"
H0=$(ledger_height)
set +e
invoke_cc "{\"function\":\"UpdateAsset\",\"Args\":[\"$ASSET_ID\",\"red\",\"25\",\"$OWNER_NOW\",\"99999\"]}" org1 2>&1 | tail -n 5
RC=${PIPESTATUS[0]}
set -e
echo "peer CLI exit code: $RC   (non-zero = tx was invalidated at commit time)"
sleep 3

step "Step 3 - diagnose: look at the world state and at the newest block"
echo "Ledger height: $H0 -> $(ledger_height)   (a block WAS added: the invalid tx is stored but not applied)"
echo "Current appraisedValue in world state: $(query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | jq -r .AppraisedValue)   (still $VAL_NOW - unchanged)"
bash "$HERE/inspect_block.sh" newest
note "Look at 'endorsed by' = only Org1MSP and 'validation result' = ENDORSEMENT_POLICY_FAILURE."
echo "Peer log evidence:"
docker logs --tail 200 peer0.org1.example.com 2>&1 | grep -Ei 'ENDORSEMENT_POLICY_FAILURE|validation code' | tail -n 2 || true

step "Step 4 - FIX: resubmit with endorsements from Org1 AND Org2"
invoke_cc "{\"function\":\"UpdateAsset\",\"Args\":[\"$ASSET_ID\",\"red\",\"25\",\"$OWNER_NOW\",\"2000\"]}" both
sleep 3
echo "New world state:"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty
bash "$HERE/inspect_block.sh" newest

cat <<'TXT'

OTHER ISSUES AN EXAMINER MAY GIVE YOU (quick diagnosis table)
  Symptom / error                                   Cause                                   Fix
  ------------------------------------------------  --------------------------------------  ---------------------------------------
  ENDORSEMENT_POLICY_FAILURE                        too few / wrong orgs endorsed           add --peerAddresses for every needed org
  MVCC_READ_CONFLICT                                key changed between simulate and commit resubmit the tx (retry)
  "chaincode basic not found / not installed"       cc not installed/committed              ./network.sh deployCC ...
  "access denied / creator org unknown"             wrong CORE_PEER_LOCALMSPID/MSP path     source set_org1 / set_org2 env
  "x509: certificate signed by unknown authority"   wrong --cafile / TLS root cert          use ORDERER_CA / peer tls ca.crt
  "connection refused localhost:7051"               network down                            backup_if_needed_auto/01_start_network.sh
  "the asset asset7 already exists"                 duplicate CreateAsset                   use new id or UpdateAsset
  "the asset assetXX does not exist"                wrong id                                GetAllAssets first
TXT
echo; echo "${C_GREEN}TASK 4b COMPLETE.${C_OFF}"
