import hashlib

def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()

def hash_pair(left, right):
    return sha(left + right)          # concatenate child hashes, then hash

def load_txs(fname="transactions.txt"):
    return [l.strip() for l in open(fname) if l.strip()]

def build_tree(leaves):
    """levels[0] = leaf hashes ... levels[-1] = [root]. Odd node is paired with itself."""
    levels = [leaves[:]]
    while len(levels[-1]) > 1:
        cur = levels[-1]
        nxt = []
        for i in range(0, len(cur), 2):
            right = cur[i + 1] if i + 1 < len(cur) else cur[i]
            nxt.append(hash_pair(cur[i], right))
        levels.append(nxt)
    return levels

def update_path(levels, idx, new_leaf):
    """Recompute ONLY the hashes on the path from leaf idx up to the root."""
    levels[0][idx] = new_leaf
    steps = [(0, idx)]
    for l in range(len(levels) - 1):
        cur = levels[l]
        left_i = idx - (idx % 2)
        right_i = left_i + 1 if left_i + 1 < len(cur) else left_i
        idx //= 2
        levels[l + 1][idx] = hash_pair(cur[left_i], cur[right_i])
        steps.append((l + 1, idx))
    return steps

def get_proof(levels, idx):
    """Merkle proof: sibling hash at each level (log2 n hashes)."""
    proof = []
    for l in range(len(levels) - 1):
        cur = levels[l]
        sib = idx ^ 1
        if sib >= len(cur):
            sib = idx
        proof.append((cur[sib], "left" if sib < idx else "right"))
        idx //= 2
    return proof

def verify_proof(leaf, proof, root):
    h = leaf
    for sib, side in proof:
        h = hash_pair(sib, h) if side == "left" else hash_pair(h, sib)
    return h == root

def short(h):
    return h[:12] + "..."