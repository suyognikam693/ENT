from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization

data = open("transaction.txt", "rb").read()
private_key = serialization.load_pem_private_key(open("private.pem", "rb").read(), password=None)

signature = private_key.sign(data, ec.ECDSA(hashes.SHA256())) 

open("signature.bin", "wb").write(signature)
print("Message   :", data.decode())
print("Signature :", signature.hex())
print("Saved to signature.bin")