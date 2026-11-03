#!/usr/bin/env bash
# Tear everything down (containers, volumes, crypto material, chaincode images).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
cd "$TEST_NET" && ./network.sh down
