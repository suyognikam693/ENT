#!/usr/bin/env bash
# Shared helpers - sourced by every script. Do not run directly.

FABRIC_SAMPLES="${FABRIC_SAMPLES:-$HOME/fabric-samples}"
TEST_NET="$FABRIC_SAMPLES/test-network"
CHANNEL="${CHANNEL:-mychannel}"
CC_NAME="${CC_NAME:-basic}"
ASSET_ID="${ASSET_ID:-asset7}"

_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$(dirname "$_SCRIPTS_DIR")"
OUT_DIR="$PKG_DIR/output"
mkdir -p "$OUT_DIR"

export PATH="$FABRIC_SAMPLES/bin:$PATH"
export FABRIC_CFG_PATH="$FABRIC_SAMPLES/config"
export CORE_PEER_TLS_ENABLED=true

ORG1_DIR="$TEST_NET/organizations/peerOrganizations/org1.example.com"
ORG2_DIR="$TEST_NET/organizations/peerOrganizations/org2.example.com"
ORG1_TLS="$ORG1_DIR/peers/peer0.org1.example.com/tls/ca.crt"
ORG2_TLS="$ORG2_DIR/peers/peer0.org2.example.com/tls/ca.crt"
ORDERER_CA="$TEST_NET/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
ORDERER_ARGS=(-o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "$ORDERER_CA")

C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_RED=$'\033[1;31m'; C_YEL=$'\033[1;33m'; C_OFF=$'\033[0m'

banner() { echo; echo "${C_BLUE}======================================================================${C_OFF}"; echo "${C_BLUE}  $*${C_OFF}"; echo "${C_BLUE}======================================================================${C_OFF}"; }
step()   { echo; echo "${C_GREEN}>>> $*${C_OFF}"; }
note()   { echo "${C_YEL}    [note] $*${C_OFF}"; }
fail()   { echo "${C_RED}ERROR: $*${C_OFF}" >&2; exit 1; }

set_org1() {
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="$ORG1_TLS"
  export CORE_PEER_MSPCONFIGPATH="$ORG1_DIR/users/Admin@org1.example.com/msp"
  export CORE_PEER_ADDRESS=localhost:7051
}
set_org2() {
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE="$ORG2_TLS"
  export CORE_PEER_MSPCONFIGPATH="$ORG2_DIR/users/Admin@org2.example.com/msp"
  export CORE_PEER_ADDRESS=localhost:9051
}

check_env() {
  [ -d "$FABRIC_SAMPLES" ] || fail "fabric-samples not found at $FABRIC_SAMPLES. Run backup_if_needed_auto/00_install_prereqs.sh first (or export FABRIC_SAMPLES=/path)."
  command -v peer >/dev/null || fail "'peer' binary not found in $FABRIC_SAMPLES/bin."
  command -v jq >/dev/null   || fail "jq not installed (sudo apt-get install -y jq)."
  docker ps >/dev/null 2>&1  || fail "Cannot talk to Docker. Is it running / is your user in the 'docker' group? (log out and in again)"
}

network_is_up() {
  docker ps --format '{{.Names}}' | grep -q '^peer0.org1.example.com$' && \
  docker ps --format '{{.Names}}' | grep -q '^orderer.example.com$'
}

require_network() {
  network_is_up || fail "Network is not running. Run backup_if_needed_auto/01_start_network.sh first."
  set_org1
  peer lifecycle chaincode querycommitted -C "$CHANNEL" -n "$CC_NAME" >/dev/null 2>&1 \
    || fail "Chaincode '$CC_NAME' not committed on '$CHANNEL'. Run backup_if_needed_auto/01_start_network.sh."
}

# invoke_cc '<json>' [both|org1]   -> goes through Proposal/Endorsement/Ordering/Commit
invoke_cc() {
  local json="$1" mode="${2:-both}"
  local peers=(--peerAddresses localhost:7051 --tlsRootCertFiles "$ORG1_TLS")
  if [ "$mode" = "both" ]; then
    peers+=(--peerAddresses localhost:9051 --tlsRootCertFiles "$ORG2_TLS")
  fi
  set_org1
  peer chaincode invoke "${ORDERER_ARGS[@]}" -C "$CHANNEL" -n "$CC_NAME" "${peers[@]}" -c "$json"
}

# query_cc '<json>'   -> read-only, answered by ONE peer from its world state, no ordering
query_cc() {
  set_org1
  peer chaincode query -C "$CHANNEL" -n "$CC_NAME" -c "$1"
}

pretty() { if command -v jq >/dev/null; then jq . 2>/dev/null || cat; else cat; fi; }

ledger_height() {
  set_org1
  peer channel getinfo -c "$CHANNEL" 2>&1 | sed -n 's/.*"height":\([0-9]*\).*/\1/p'
}

asset_exists() {
  [ "$(query_cc "{\"function\":\"AssetExists\",\"Args\":[\"$1\"]}" 2>/dev/null)" = "true" ]
}
