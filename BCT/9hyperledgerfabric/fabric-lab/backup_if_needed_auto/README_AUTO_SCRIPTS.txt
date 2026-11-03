=====================================================================
 HYPERLEDGER FABRIC LAB  -  HOW TO RUN  (Ubuntu 20.04 / 22.04 / 24.04)
=====================================================================
Uses the official Hyperledger Fabric "test-network" (2 peer orgs + 1 Raft orderer,
channel "mychannel") and the official "asset-transfer-basic" chaincode (Go).
Everything is driven by the Fabric peer CLI, so no extra application is needed.

PACKAGE CONTENTS
  INSTRUCTIONS.txt            this file
  VIVA_QA.txt                 viva questions and answers
  backup_if_needed_auto/common.sh           shared helpers (env vars, org switching, invoke/query)
  backup_if_needed_auto/00_install_prereqs.sh   install Docker, Go, jq + download Fabric binaries/images/samples
  backup_if_needed_auto/01_start_network.sh     TASK 1  start/verify network, channel, chaincode, list orgs & peers
  backup_if_needed_auto/02_create_query_asset.sh TASK 2 create + query an asset
  backup_if_needed_auto/03_update_transfer_asset.sh TASK 3 update + transfer, verify world state and ledger blocks
  backup_if_needed_auto/04_transaction_flow_demo.sh TASK 4a transaction flow demonstration with logs + decoded block
  backup_if_needed_auto/05_policy_troubleshoot.sh   TASK 4b endorsement-policy failure, diagnosis and fix
  backup_if_needed_auto/inspect_block.sh/.py    fetch + decode any block (who/what/endorsers/rw-set/validation)
  backup_if_needed_auto/run_all.sh              runs tasks 1-4 in sequence
  backup_if_needed_auto/99_stop_network.sh      tear down

---------------------------------------------------------------------
 STEP 0 - ONE-TIME SETUP  (needs internet, ~10-20 min, ~3 GB download)
---------------------------------------------------------------------
  unzip fabric-lab.zip
  cd fabric-lab
  bash backup_if_needed_auto/00_install_prereqs.sh
  # then LOG OUT and LOG IN again (or run: newgrp docker) so Docker works without sudo
  docker ps          # must work without sudo

If the exam machine ALREADY has Fabric installed ("preconfigured"):
  skip step 0 and tell the scripts where it is:
      export FABRIC_SAMPLES=/path/to/fabric-samples     (default: $HOME/fabric-samples)
  Optional overrides:  CHANNEL=mychannel  CC_NAME=basic  ASSET_ID=asset7

---------------------------------------------------------------------
 TASK 1 - Start / verify network, identify organisations and peers
---------------------------------------------------------------------
  bash backup_if_needed_auto/01_start_network.sh
  - If the network is already running it only VERIFIES it. FORCE=1 rebuilds from scratch.
  Expected: containers peer0.org1, peer0.org2, orderer, 3 CAs; "mychannel" listed for both peers;
  Application orgs ["Org1MSP","Org2MSP"], Orderer org ["OrdererMSP"], chaincode "basic" committed
  with approvals Org1MSP: true, Org2MSP: true.

---------------------------------------------------------------------
 TASK 2 - Create / query an asset
---------------------------------------------------------------------
  bash backup_if_needed_auto/02_create_query_asset.sh            # creates asset7 (blue, 20, Tomoko, 500)
  ASSET_ID=asset9 bash backup_if_needed_auto/02_create_query_asset.sh      # different id
  Expected: ReadAsset prints JSON {"ID":"asset7","Color":"blue","Size":20,"Owner":"Tomoko","AppraisedValue":500}
  and ledger height increases by 1 for the create.

---------------------------------------------------------------------
 TASK 3 - Update / transfer and verify
---------------------------------------------------------------------
  bash backup_if_needed_auto/03_update_transfer_asset.sh          # NEW_OWNER=Priya by default
  NEW_OWNER=Rahul bash backup_if_needed_auto/03_update_transfer_asset.sh
  Expected: color blue->green, value 500->750, owner Tomoko->Priya; script prints
  "VERIFIED: owner is now Priya" and decodes the new blocks showing WRITE asset7 = {...}.

---------------------------------------------------------------------
 TASK 4 - Transaction flow / troubleshooting
---------------------------------------------------------------------
  bash backup_if_needed_auto/04_transaction_flow_demo.sh          # flow diagram, logs, decoded block
  bash backup_if_needed_auto/05_policy_troubleshoot.sh            # one-org endorsement => ENDORSEMENT_POLICY_FAILURE, then fix
  bash backup_if_needed_auto/inspect_block.sh newest              # decode the latest block at any time
  bash backup_if_needed_auto/inspect_block.sh 5                   # decode block number 5

RUN EVERYTHING:  PAUSE=1 bash backup_if_needed_auto/run_all.sh    (ENTER between tasks - good for the viva)
CLEAN UP:        bash backup_if_needed_auto/99_stop_network.sh

---------------------------------------------------------------------
 MANUAL COMMANDS (if the examiner asks you to type them yourself)
---------------------------------------------------------------------
  cd ~/fabric-samples/test-network
  export PATH=${PWD}/../bin:$PATH
  export FABRIC_CFG_PATH=$PWD/../config/
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID=Org1MSP
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051

  # start
  ./network.sh down
  ./network.sh up createChannel -c mychannel -ca
  ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

  # query (read only)
  peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
  peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset","asset1"]}'

  # invoke (write; must be endorsed by both orgs)
  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls \
    --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    -C mychannel -n basic \
    --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt \
    -c '{"function":"CreateAsset","Args":["asset8","red","10","Alice","300"]}'
  (other functions: UpdateAsset id color size owner value | TransferAsset id newOwner | DeleteAsset id | AssetExists id)

  # ledger info
  peer channel getinfo -c mychannel
  # logs
  docker logs peer0.org1.example.com 2>&1 | tail -n 30
  docker logs orderer.example.com 2>&1 | tail -n 30

---------------------------------------------------------------------
 TROUBLESHOOTING THE SETUP
---------------------------------------------------------------------
  "permission denied ... docker.sock"   -> log out/in after step 0, or: sudo usermod -aG docker $USER && newgrp docker
  "fabric-samples not found"            -> run step 0, or export FABRIC_SAMPLES=...
  "peer: command not found"             -> $FABRIC_SAMPLES/bin missing; re-run step 0
  deployCC fails at go mod vendor       -> Go missing/old: run step 0 (installs Go) and 'source ~/.profile'
  ports 7050/7051/9051 in use           -> bash backup_if_needed_auto/99_stop_network.sh ; docker ps -a ; stop other containers
  stale/odd state                       -> FORCE=1 bash backup_if_needed_auto/01_start_network.sh
  Block "newest" fetch fails            -> network not up; run Task 1 script
  Old docker-compose only               -> sudo apt-get install -y docker-compose-v2
NOTE: scripts print "[note]" lines in yellow to explain what is happening - useful to read aloud in the viva.
