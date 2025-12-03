// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Contract for an unburnable token
contract UnburnableToken {
    string private salt = "value"; // A private string variable

    // Mapping to track token balances of addresses
    mapping(address => uint256) public balances;

    uint256 public totalSupply; // Total supply of tokens
    uint256 public totalClaimed; // Total number of tokens claimed
    mapping(address => bool) private claimed; // Mapping to track whether an address has claimed tokens

    // Custom errors
    error TokensClaimed(); // Error for attempting to claim tokens again
    error AllTokensClaimed(); // Error for attempting to claim tokens when all are already claimed
    error UnsafeTransfer(address _to); // Error for unsafe token transfer

    // Constructor to set the total supply of tokens
    constructor() {
        totalSupply = 100000000; // Set the total supply of tokens
    }

    // Public function to claim tokens
    function claim() public {
        // Check if all tokens have been claimed
        if (totalClaimed >= totalSupply) revert AllTokensClaimed();

        // Check if the caller has already claimed tokens
        if (claimed[msg.sender]) revert TokensClaimed();

        // Update balances and claimed status
        balances[msg.sender] += 1000;
        totalClaimed += 1000;
        claimed[msg.sender] = true;
    }

    // Public function for safe token transfer
    function safeTransfer(address _to, uint256 _amount) public {
        // Check for unsafe transfer conditions, including if the target address has a non-zero ether balance
        if (_to == address(0) || _to.balance == 0) revert UnsafeTransfer(_to);

        // Ensure the sender has enough balance to transfer
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Perform the transfer
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
}
