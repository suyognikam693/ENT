"""
Lab 4 – Proof-of-Work, Nonce and Mining Difficulty
Menu-Driven Interactive Implementation covering Tasks 1, 2, 3, and 4.
"""

import hashlib
import time

# =====================================================================
# TASK 1: Proof-of-Work Mining Engine Function & Verification
# =====================================================================
def proof_of_work(block_data: str, difficulty: int) -> dict:
    """
    Core PoW Algorithm (Task 1 Engine):
    Mines a block payload by incrementing nonce until hash starts with `difficulty` zero digits.
    Returns dictionary with nonce, output hash, attempt count, and runtime.
    """
    target_prefix = "0" * difficulty
    nonce = 0
    start_time = time.time()

    while True:
        payload = f"{block_data}{nonce}".encode("utf-8")
        hash_result = hashlib.sha256(payload).hexdigest()

        if hash_result.startswith(target_prefix):
            elapsed_time = time.time() - start_time
            return {
                "difficulty": difficulty,
                "nonce": nonce,
                "hash": hash_result,
                "attempts": nonce + 1,
                "time_sec": elapsed_time
            }
        nonce += 1


def execute_task_1(difficulty: int = 2):
    """
    Verifies Task 1 functionality by running a basic PoW calculation.
    """
    print("\n" + "=" * 65)
    print(f" TASK 1: Proof-of-Work Engine Functional Test (Difficulty: {difficulty})")
    print("=" * 65)
    
    test_data = "Lab4_Task1_Initialization_Test"
    metrics = proof_of_work(test_data, difficulty)
    
    print("Status:                 PoW Engine Initialized & Working")
    print(f"Input Data String:      '{test_data}'")
    print(f"Target Prefix Required: '{'0' * metrics['difficulty']}'")
    print(f"Validated Hash Result:  {metrics['hash']}")
    print(f"Nonce Found:            {metrics['nonce']}")


# =====================================================================
# TASK 2: Mine Single Block & Report Detailed Metrics
# =====================================================================
def execute_task_2(difficulty: int = 4):
    """
    Mines a single block and displays nonce, hash, iterations, and runtime.
    """
    print("\n" + "=" * 65)
    print(f" TASK 2: Mine Block & Report Nonce, Hash & Attempts (Difficulty: {difficulty})")
    print("=" * 65)
    
    block_data = "Block_#101[Sender:Alice, Receiver:Bob, Amount:12.5_BTC]"
    metrics = proof_of_work(block_data, difficulty)

    print(f"Target Prefix Required: '{'0' * metrics['difficulty']}'")
    print(f"Resulting Nonce:        {metrics['nonce']}")
    print(f"Resulting Hash:         {metrics['hash']}")
    print(f"Total Iterations:       {metrics['attempts']:,}")
    print(f"Execution Time:         {metrics['time_sec']:.4f} seconds")


# =====================================================================
# TASK 3: Vary Difficulty & Measure Observed Effort
# =====================================================================
def execute_task_3(difficulties: list):
    """
    Runs PoW across multiple difficulty levels to measure time and attempt growth.
    """
    print("\n" + "=" * 85)
    print(" TASK 3: Mining Difficulty & Computational Effort Comparison")
    print("=" * 85)
    
    block_data = "Block_#102[Tx_Root: 0x9f8a7c...]"
    print(f"{'Diff':<6} | {'Attempts':<12} | {'Time (s)':<10} | {'Growth Factor':<14} | {'Resulting Hash'}")
    print("-" * 85)

    previous_attempts = None
    for diff in difficulties:
        res = proof_of_work(block_data, diff)
        
        # Calculate attempt scaling ratio relative to previous difficulty step
        growth = f"{res['attempts'] / previous_attempts:.2f}x" if previous_attempts else "Baseline"
        previous_attempts = res['attempts']
        
        print(f"{res['difficulty']:<6} | {res['attempts']:<12,} | {res['time_sec']:<10.4f} | {growth:<14} | {res['hash'][:24]}...")


# =====================================================================
# TASK 4: Target Threshold & Difficulty Relationship Analysis
# =====================================================================
def execute_task_4(difficulty: int):
    """
    Calculates and displays the exact target threshold, search space size,
    and theoretical expected effort for a given difficulty level.
    """
    print("\n" + "=" * 85)
    print(f" TASK 4: Target, Difficulty, and Effort Relationship (Difficulty: {difficulty})")
    print("=" * 85)

    # SHA-256 target calculation in 256-bit space
    target_hex = "0" * difficulty + "f" * (64 - difficulty)
    target_int = int(target_hex, 16)
    max_target = 2**256 - 1
    
    # Success probability and theoretical expected attempts
    probability = target_int / max_target
    expected_attempts = 16**difficulty

    print(f"1. Leading Zero Target Prefix:  {'0' * difficulty}")
    print(f"2. Numerical Target Threshold:  0x{target_hex}")
    print(f"3. Relative Target Size:        {target_int / max_target:.6%}")
    print(f"4. Success Probability (p):     {probability:.6e} (1 in 16^{difficulty})")
    print(f"5. Theoretical Expected Engine:  {expected_attempts:,} attempts")


# =====================================================================
# INTERACTIVE MENU SYSTEM
# =====================================================================
def main_menu():
    """
    Interactive terminal menu allowing individual task execution or full lab run.
    """
    while True:
        print("\n" + "=" * 65)
        print("          LAB 4: PROOF-OF-WORK LAB - MAIN MENU")
        print("=" * 65)
        print("  [1] Task 1: Run PoW Engine Functional Test")
        print("  [2] Task 2: Mine Block & Report Nonce/Hash/Attempts")
        print("  [3] Task 3: Compare Effort Across Multiple Difficulties")
        print("  [4] Task 4: Analyze Target, Difficulty & Probability")
        print("  [5] Run ALL Tasks Sequentially (Full Lab Suite)")
        print("  [0] Exit Program")
        print("=" * 65)
        
        choice = input("Select an option (0-5): ").strip()

        if choice == "1":
            user_diff = input("Enter target difficulty [Default: 2]: ").strip()
            diff = int(user_diff) if user_diff.isdigit() and int(user_diff) > 0 else 2
            execute_task_1(difficulty=diff)

        elif choice == "2":
            user_diff = input("Enter target difficulty [Default: 4]: ").strip()
            diff = int(user_diff) if user_diff.isdigit() and int(user_diff) > 0 else 4
            execute_task_2(difficulty=diff)

        elif choice == "3":
            diff_input = input("Enter difficulty values separated by space [Default: 1 2 3 4 5]: ").strip()
            if diff_input:
                try:
                    diffs = [int(x) for x in diff_input.split() if int(x) > 0]
                except ValueError:
                    print("[!] Invalid input. Falling back to default: [1, 2, 3, 4, 5]")
                    diffs = [1, 2, 3, 4, 5]
            else:
                diffs = [1, 2, 3, 4, 5]
            execute_task_3(difficulties=diffs)

        elif choice == "4":
            user_diff = input("Enter target difficulty [Default: 5]: ").strip()
            diff = int(user_diff) if user_diff.isdigit() and int(user_diff) > 0 else 5
            execute_task_4(difficulty=diff)

        elif choice == "5":
            print("\n>>> RUNNING FULL LAB SUITE <<<")
            execute_task_1(difficulty=2)
            execute_task_2(difficulty=4)
            execute_task_3(difficulties=[1, 2, 3, 4, 5])
            execute_task_4(difficulty=5)

        elif choice == "0":
            print("\nExiting Proof-of-Work Lab. Goodbye!\n")
            break

        else:
            print("\n[!] Invalid option. Please enter a number from 0 to 5.")


# =====================================================================
# Main Execution Entry Point
# =====================================================================
if __name__ == "__main__":
    main_menu()