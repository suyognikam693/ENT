data = open("transaction.txt").read()
tampered = data.replace("Alice pays Bob 10 BTC", "Alice pays Bob 1000 BTC")
open("tampered.txt", "w").write(tampered)
print("tampered.txt created (TX1 amount changed 10 -> 1000 BTC)")