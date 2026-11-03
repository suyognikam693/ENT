// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vault {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // ===== VULNERABLE: no balance check, unchecked underflow =====
    function withdraw(uint256 amt) public {
        unchecked {
            balances[msg.sender] -= amt;   // underflows to a huge number
        }
        (bool ok, ) = payable(msg.sender).call{value: amt}("");
        require(ok, "Transfer failed");
    }

    // ===== FIXED: uncomment this block and comment out the vulnerable withdraw above =====
    // function withdraw(uint256 amt) public {
    //     require(amt > 0, "Zero amount");
    //     require(balances[msg.sender] >= amt, "Insufficient balance");  // validation
    //     balances[msg.sender] -= amt;                                    // effects first
    //     (bool ok, ) = payable(msg.sender).call{value: amt}("");         // checked call
    //     require(ok, "Transfer failed");
    // }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}