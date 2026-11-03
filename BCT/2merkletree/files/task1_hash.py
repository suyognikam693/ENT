from merkle_lib import *

txs = load_txs()
print("TASK 1: SHA-256 hash of each transaction\n")
for i, t in enumerate(txs, 1):
    print(f"H{i} = {sha(t)}")
    print(f"     <- {t}\n")