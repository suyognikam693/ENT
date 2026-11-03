// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {}

    // ===== VULNERABLE: anyone can become owner =====
    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    // ===== FIXED: uncomment this block and comment out the vulnerable setOwner above =====
    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Not owner");
    //     _;
    // }
    // function setOwner(address newOwner) public onlyOwner {
    //     require(newOwner != address(0), "Zero address");
    //     owner = newOwner;
    // }

    // ===== VULNERABLE withdrawAll: only checks owner variable, which anyone can overwrite =====
    function withdrawAll() public {
        require(msg.sender == owner, "Not owner");
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}