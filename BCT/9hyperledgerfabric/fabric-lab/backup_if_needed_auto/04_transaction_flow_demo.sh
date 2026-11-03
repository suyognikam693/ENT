#!/usr/bin/env bash
# TASK 4a - Explain & demonstrate  Proposal -> Endorsement -> Ordering -> Validation -> Commit
# Usage: bash backup_if_needed_auto/04_transaction_flow_demo.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
check_env; require_network

banner "TASK 4a: Transaction flow demonstration"
asset_exists "$ASSET_ID" || fail "$ASSET_ID missing - run backup_if_needed_auto/02_create_query_asset.sh"

cat <<'TXT'

   CLIENT (peer CLI, Admin@org1)
     |  1. PROPOSAL     signed proposal  (channel, chaincode, function, args)
     v
   ENDORSING PEERS  peer0.org1 + peer0.org2
     |  2. ENDORSEMENT  each peer SIMULATES the chaincode against its world state,
     |                  produces a read-write set, and signs the response. NOTHING is committed yet.
     v
   CLIENT   collects endorsements, checks they match, builds a transaction envelope
     |  3. ORDERING     sends the envelope to orderer.example.com (Raft). The orderer does NOT run
     |                  chaincode - it only orders txs and cuts them into blocks.
     v
   ALL PEERS (receive the block from the orderer / gossip)
        4. VALIDATION   (a) endorsement policy satisfied?  (b) MVCC: read versions still current?
        5. COMMIT       block appended to ledger, valid write-sets applied to world state,
                        invalid txs are kept in the block but flagged and NOT applied.
TXT

TS_START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
H0=$(ledger_height)
step "State BEFORE:  ledger height = $H0"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty

step "(read-only) QUERY goes to ONE peer, is not ordered, creates no block"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" >/dev/null
echo "Height after query: $(ledger_height)  (unchanged)"

NEWVAL=$((RANDOM % 900 + 100))
step "INVOKE UpdateAsset with endorsement from BOTH orgs  (new appraisedValue=$NEWVAL)"
note "1) CLI builds+signs PROPOSAL   2) sends to peer0.org1:7051 and peer0.org2:9051 (ENDORSEMENT)"
note "3) CLI sends endorsed tx to orderer:7050 (ORDERING)   4+5) peers VALIDATE and COMMIT; CLI waits for the commit event"
OWNER_NOW=$(query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | jq -r .Owner)
invoke_cc "{\"function\":\"UpdateAsset\",\"Args\":[\"$ASSET_ID\",\"green\",\"25\",\"$OWNER_NOW\",\"$NEWVAL\"]}" both
sleep 3
H1=$(ledger_height)
step "State AFTER:  ledger height = $H1"
query_cc "{\"function\":\"ReadAsset\",\"Args\":[\"$ASSET_ID\"]}" | pretty

banner "Evidence from the component logs (since $TS_START)"
step "ENDORSING PEER logs - chaincode simulation (Proposal/Endorsement)"
for p in peer0.org1.example.com peer0.org2.example.com; do
  echo "--- $p"
  docker logs --since "$TS_START" "$p" 2>&1 | grep -Ei 'Entry chaincode|Exit chaincode|endorser' | tail -n 4 || true
done
step "ORDERER log - block creation (Ordering)"
docker logs --since "$TS_START" orderer.example.com 2>&1 | grep -Ei 'block \[|Writing block|Created block' | tail -n 3 || echo "(no matching lines - orderer log level may differ)"
step "COMMITTING PEER logs - validate + commit"
for p in peer0.org1.example.com peer0.org2.example.com; do
  echo "--- $p"
  docker logs --since "$TS_START" "$p" 2>&1 | grep -Ei 'Validated block|Committed block|Received block' | tail -n 3 || true
done

step "The committed block itself, decoded (proof of every stage: creator, endorsers, rw-set, validation flag)"
bash "$(dirname "${BASH_SOURCE[0]}")/inspect_block.sh" newest

cat <<'TXT'

HOW TO READ THE BLOCK ABOVE
  submitted by MSP     -> who created the PROPOSAL
  endorsed by          -> ENDORSEMENT (policy: majority of orgs = both Org1MSP and Org2MSP)
  block # / hashes     -> ORDERING output (orderer cut the block, chained by previous_hash)
  validation result    -> VALIDATION (VALID = policy OK + no MVCC conflict)
  READ / WRITE entries -> read-write set; WRITE values are what COMMIT put into the world state
TXT
echo; echo "${C_GREEN}TASK 4a COMPLETE.${C_OFF}"
