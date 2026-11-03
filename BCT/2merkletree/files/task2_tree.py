from merkle_lib import *

txs = load_txs()
leaves = [sha(t) for t in txs]
levels = build_tree(leaves)

print("TASK 2: Merkle Tree\n")
for l, level in enumerate(levels):
    name = "Leaf hashes" if l == 0 else ("MERKLE ROOT" if l == len(levels) - 1 else f"Level {l}")
    print(f"--- {name} ---")
    for i, h in enumerate(level):
        print(f"  [{l},{i}] {h}")
    print()

print("Tree height   :", len(levels) - 1)
print("MERKLE ROOT   :", levels[-1][0])
open("original_root.txt", "w").write(levels[-1][0])