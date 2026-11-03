#!/usr/bin/env bash
# TASK 1 - Start (or verify) the Fabric test network + channel, deploy chaincode,
#          and identify the participating organisations / peers.
# Usage:  bash backup_if_needed_auto/01_start_network.sh            (start if needed, then verify)
#         FORCE=1 bash backup_if_needed_auto/01_start_network.sh    (tear down and rebuild from scratch)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env
command -v configtxlator >/dev/null || fail "configtxlator missing from $FABRIC_SAMPLES/bin"

banner "TASK 1: Start / verify the Fabric test network"

already_up=false
if [ "${FORCE:-0}" != "1" ] && network_is_up; then
  set_org1
  if peer lifecycle chaincode querycommitted -C "$CHANNEL" -n "$CC_NAME" >/dev/null 2>&1; then
    already_up=true
  fi
fi

if $already_up; then
  note "Network, channel '$CHANNEL' and chaincode '$CC_NAME' are already running - verifying only."
else
  step "Bringing up network: 2 peer orgs + 1 orderer, CA enabled, channel '$CHANNEL'"
  cd "$TEST_NET"
  ./network.sh down
  ./network.sh up createChannel -c "$CHANNEL" -ca
  step "Packaging, installing, approving (Org1 + Org2) and committing chaincode '$CC_NAME' (asset-transfer-basic, Go)"
  ./network.sh deployCC -ccn "$CC_NAME" -ccp ../asset-transfer-basic/chaincode-go -ccl go
  cd - >/dev/null
fi

# ---------------------------------------------------------------- verification
banner "VERIFICATION: running containers"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' | grep -E 'NAMES|peer|orderer|ca_|couchdb' || true

step "Channels joined by peer0.org1 (Org1MSP)"
set_org1;  peer channel list 2>&1 | grep -vE '^\s*$' | tail -n 3
step "Channels joined by peer0.org2 (Org2MSP)"
set_org2;  peer channel list 2>&1 | grep -vE '^\s*$' | tail -n 3

step "Ledger info for '$CHANNEL' (height = number of blocks)"
set_org1;  peer channel getinfo -c "$CHANNEL" 2>&1 | tail -n 1

step "Fetching the channel configuration to list participating organisations"
set_org1
peer channel fetch config "$OUT_DIR/config_block.pb" "${ORDERER_ARGS[@]}" -c "$CHANNEL" >/dev/null 2>&1
configtxlator proto_decode --input "$OUT_DIR/config_block.pb" --type common.Block --output "$OUT_DIR/config_block.json"
CFG='.data.data[0].payload.data.config.channel_group.groups'
echo "Application (peer) organisations : $(jq -c "$CFG.Application.groups | keys" "$OUT_DIR/config_block.json")"
echo "Orderer organisations            : $(jq -c "$CFG.Orderer.groups | keys" "$OUT_DIR/config_block.json")"
echo "Consensus type                   : $(jq -r "$CFG.Orderer.values.ConsensusType.value.type" "$OUT_DIR/config_block.json")"
echo "Channel Application policies     : $(jq -c "$CFG.Application.policies | keys" "$OUT_DIR/config_block.json")"

step "Participants summary"
cat <<TXT
  Organisation   MSP ID     Peer                      Peer endpoint      Role
  Org1           Org1MSP    peer0.org1.example.com    localhost:7051     endorser + committer
  Org2           Org2MSP    peer0.org2.example.com    localhost:9051     endorser + committer
  OrdererOrg     OrdererMSP orderer.example.com       localhost:7050     ordering service (Raft)
  Fabric CAs     ca_org1 (7054), ca_org2 (8054), ca_orderer (9054)  - issue identities
TXT

step "Chaincode definition committed on the channel (note the approvals per org)"
set_org1
peer lifecycle chaincode querycommitted -C "$CHANNEL" -n "$CC_NAME" 2>&1
step "Chaincode installed on peer0.org1 / peer0.org2"
set_org1; peer lifecycle chaincode queryinstalled 2>&1 | grep -E 'Package ID' | sed 's/^/  org1: /'
set_org2; peer lifecycle chaincode queryinstalled 2>&1 | grep -E 'Package ID' | sed 's/^/  org2: /'
set_org1

echo; echo "${C_GREEN}TASK 1 COMPLETE - network healthy.${C_OFF}"
