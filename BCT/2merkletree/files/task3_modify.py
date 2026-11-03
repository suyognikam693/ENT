import sys, copy
from merkle_lib import *

idx = int(sys.argv[1]) if len(sys.argv) > 1 else 2      # 0-based, default = TX3
new_tx = sys.argv[2] if len(sys.argv) > 2 else \
    "TX3: Charlie pays Dave 75 BTC | Nonce: 1023 | Timestamp: 2026-11-02 10:12"

txs = load_txs()
levels = build_tree([sha(t) for t in txs])
old_root = levels[-1][0]

print("TASK 3: Modify one transaction, recompute only the affected path\n")
print("Original TX :", txs[idx])
print("Modified TX :", new_tx)

# save modified file for Task 4
mod_txs = txs[:]
mod_txs[idx] = new_tx
open("modified_transactions.txt", "w").write("\n".join(mod_txs) + "\n")

new_levels = copy.deepcopy(levels)
steps = update_path(new_levels, idx, sha(new_tx))

print("\nRecomputed nodes (only these changed):")
for (l, i) in steps:
    print(f"  node [{l},{i}]  old {short(levels[l][i])}  ->  new {short(new_levels[l][i])}")

total = sum(len(x) for x in levels)
print(f"\nHashes recomputed: {len(steps)} out of {total} nodes (the rest are reused)")
print("Old Merkle Root :", old_root)
print("New Merkle Root :", new_levels[-1][0])

# sanity check: full rebuild gives the same root
check = build_tree([sha(t) for t in mod_txs])[-1][0]
print("Matches full rebuild:", check == new_levels[-1][0])