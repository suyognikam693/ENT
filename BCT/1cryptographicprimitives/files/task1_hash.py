import hashlib, sys

fname = sys.argv[1] if len(sys.argv) > 1 else "transaction.txt"
data = open(fname, "rb").read()

print("Message :", data.decode())
print("SHA-256 :", hashlib.sha256(data).hexdigest())