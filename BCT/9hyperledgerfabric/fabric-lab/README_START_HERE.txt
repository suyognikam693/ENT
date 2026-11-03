=====================================================================
 HYPERLEDGER FABRIC LAB - START HERE
=====================================================================
Problem statement covered:
  Task 1  Start/verify preconfigured test network + channel, identify orgs/peers
  Task 2  Create / query an asset using the chaincode through the CLI
  Task 3  Update / transfer the asset and verify the changed ledger / world state
  Task 4  Explain + demonstrate Proposal > Endorsement > Ordering > Validation > Commit,
          or troubleshoot a small transaction/policy issue

FOLDER LAYOUT
  fabric-lab/
   |- README_START_HERE.txt                       <- this file
   |- TASK0_setup.txt                             one-time install (skip if Fabric is already on the machine)
   |- TASK1_start_verify_network.txt              step-by-step commands + expected output + what to say
   |- TASK2_create_query_asset.txt
   |- TASK3_update_transfer_asset.txt
   |- TASK4_transaction_flow_and_troubleshooting.txt
   |- VIVA_QA.txt                                 45 viva questions with answers
   |- code/
   |    |- env_common.env      shared settings + helper functions (q, invoke_both, invoke_org1, height, show_block)
   |    |- env_org1.env        "become" Org1 Admin  (peer0.org1, port 7051)
   |    |- env_org2.env        "become" Org2 Admin  (peer0.org2, port 9051)
   |    |- inspect_block.py    decodes a Fabric block into readable text (used by show_block)
   |- backup_if_needed_auto/   shell scripts that do all tasks automatically (ONLY a fallback)

WHERE TO PUT THINGS
  1. Unzip anywhere, recommended:   ~/fabric-lab
  2. Fabric itself lives in:        ~/fabric-samples      (created by TASK0, or already present on the exam PC)
     If it is somewhere else:       export FABRIC_SAMPLES=/the/real/path     (before sourcing the env files)
  3. You do NOT copy the code/ files anywhere. You just "source" them from where they are:
         source ~/fabric-lab/code/env_org1.env
     Do this in EVERY new terminal window - environment variables are per terminal.

HOW TO WORK (the rhythm of the exam)
  - Open ONE terminal for commands. Optionally a 2nd terminal for "docker logs -f ..." in Task 4.
  - Do the task files in order 1 -> 2 -> 3 -> 4. Each file says: command, what you should see, what to say.
  - If something goes wrong and you are short of time, use backup_if_needed_auto/README_AUTO_SCRIPTS.txt.

CONVENTIONS USED IN THE TASK FILES
  $ command        = type this in the terminal
  (expect) ...     = what the output should look like
  SAY: ...         = one-line explanation for the examiner
