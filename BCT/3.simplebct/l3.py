import hashlib
import time


# Task 1: block structure
class Block:
    def __init__(self, index, data, prev_hash):
        self.index = index
        self.timestamp = time.ctime()
        self.data = data
        self.prev_hash = prev_hash
        self.hash = self.calc_hash()

    def calc_hash(self):
        s = str(self.index) + self.timestamp + self.data + self.prev_hash
        return hashlib.sha256(s.encode()).hexdigest()


# Task 2: add block (links to previous block's hash)
def add_block(chain, data):
    chain.append(Block(len(chain), data, chain[-1].hash))


def show(chain):
    for b in chain:
        print(b.index, "|", b.data, "| prev:", b.prev_hash[:10], "| hash:", b.hash[:10])


# Task 3: validation
def is_valid(chain):
    for i in range(len(chain)):
        if chain[i].hash != chain[i].calc_hash():
            print("Block", i, "hash is wrong (data changed)")
            return False
        if i > 0 and chain[i].prev_hash != chain[i - 1].hash:
            print("Block", i, "prev hash does not match block", i - 1)
            return False
    return True


# shows every block, does not stop at first error
def status(chain):
    for i in range(len(chain)):
        ok = chain[i].hash == chain[i].calc_hash()
        if i > 0 and chain[i].prev_hash != chain[i - 1].hash:
            ok = False
        print("  Block", i, "OK" if ok else "BROKEN")


def get_block_number(chain):
    try:
        num = int(input("Enter block number (0 to " + str(len(chain) - 1) + "): "))
    except ValueError:
        print("Please enter a number")
        return -1
    if num < 0 or num >= len(chain):
        print("No such block")
        return -1
    return num


chain = [Block(0, "Genesis", "0")]
print("Blockchain created with genesis block.")
print("Add at least 3 blocks, validate, then tamper and check again.")

while True:
    print("\n1.Add block  2.Show chain  3.Validate  4.Tamper  5.Status of blocks  6.Recalculate hash  7.Exit")
    choice = input("Your choice: ")

    if choice == "1":
        data = input("Enter data for new block: ")
        add_block(chain, data)
        print("Block", len(chain) - 1, "added.")

    elif choice == "2":
        show(chain)

    elif choice == "3":
        print("Valid:", is_valid(chain))

    elif choice == "4":
        n = get_block_number(chain)
        if n != -1:
            print("Old data:", chain[n].data)
            chain[n].data = input("Enter new data: ")
            print("Block", n, "data changed.")

    elif choice == "5":
        status(chain)

    elif choice == "6":
        # attacker recalculates the hash of a block to hide the change
        n = get_block_number(chain)
        if n != -1:
            if n > 0:
                chain[n].prev_hash = chain[n - 1].hash
            chain[n].hash = chain[n].calc_hash()
            print("Block", n, "hash recalculated.")

    elif choice == "7":
        print("Bye")
        break

    else:
        print("Wrong choice, try again")