#!/usr/bin/env bash
# Fetch a block from the channel, decode it, and print a readable summary.
# Usage: bash backup_if_needed_auto/inspect_block.sh newest | <block-number>
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env
command -v configtxlator >/dev/null || fail "configtxlator not found"
WHICH="${1:-newest}"
set_org1
rm -f "$OUT_DIR/block_$WHICH.pb"
peer channel fetch "$WHICH" "$OUT_DIR/block_$WHICH.pb" "${ORDERER_ARGS[@]}" -c "$CHANNEL" >/dev/null 2>&1 \
  || fail "Could not fetch block '$WHICH' (does it exist?)"
configtxlator proto_decode --input "$OUT_DIR/block_$WHICH.pb" --type common.Block --output "$OUT_DIR/block_$WHICH.json"
python3 "$(dirname "${BASH_SOURCE[0]}")/inspect_block.py" "$OUT_DIR/block_$WHICH.json"
