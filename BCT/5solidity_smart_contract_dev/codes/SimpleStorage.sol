// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStorage {

    address public owner;
    uint256 private storedData;

    constructor() {
        owner = msg.sender;
        storedData = 0;
    }

    function set(uint256 x) public {
        require(msg.sender == owner, "Only owner can update");
        require(x <= 100, "Value must be between 0 and 100");

        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}
