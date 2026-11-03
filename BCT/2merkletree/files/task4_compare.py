from merkle_lib import *

orig = load_txs("transactions.txt")
mod = load_txs("modified_transactions.txt")
lo = build_tree([sha(t) for t in orig])
lm = build_tree([sha(t) for t in mod])

print("TASK 4: Compare original and modified Merkle Roots\n")
print("Original root :", lo[-1][0])
print("Modified root :", lm[-1][0])
print("Roots equal   :", lo[-1][0] == lm[-1][0])
print("=> TAMPERING DETECTED" if lo[-1][0] != lm[-1][0] else "=> Data intact")

print("\nNodes that differ:")
for l in range(len(lo)):
    for i in range(len(lo[l])):
        if lo[l][i] != lm[l][i]:
            print(f"  [{l},{i}] {short(lo[l][i])} != {short(lm[l][i])}")

# Merkle proof demo: verify one tx using only log2(n) hashes
idx = [i for i in range(len(orig)) if orig[i] != mod[i]][0]
proof = get_proof(lo, idx)
print(f"\nMerkle proof for TX{idx+1} has {len(proof)} hashes (tree has {len(orig)} transactions)")
print("Original tx verifies vs original root:", verify_proof(sha(orig[idx]), proof, lo[-1][0]))
print("Modified tx verifies vs original root:", verify_proof(sha(mod[idx]), proof, lo[-1][0]))