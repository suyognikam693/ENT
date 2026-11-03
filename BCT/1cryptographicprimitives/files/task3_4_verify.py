import sys
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.exceptions import InvalidSignature

fname = sys.argv[1] if len(sys.argv) > 1 else "transaction.txt"
data = open(fname, "rb").read()
signature = open("signature.bin", "rb").read()
public_key = serialization.load_pem_public_key(open("public.pem", "rb").read())

print("Verifying file:", fname)
print("Message       :", data.decode())

try:
    public_key.verify(signature, data, ec.ECDSA(hashes.SHA256()))
    print("RESULT: Signature VALID - data is authentic and unmodified")
except InvalidSignature:
    print("RESULT: Signature INVALID - data was tampered or wrong key")