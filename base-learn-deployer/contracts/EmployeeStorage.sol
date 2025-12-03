// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EmployeeStorage {
    // Declare private state variables to store employee data
    uint16 private shares; // Number of shares owned by the employee (private to contract)
    uint32 private salary; // Monthly salary of the employee (private to contract)
    uint256 public idNumber; // Unique identification number of the employee (publicly accessible)
    string public name; // Name of the employee (publicly accessible)

    // Constructor to initialize employee data when contract is deployed
    constructor(uint16 _shares, string memory _name, uint32 _salary, uint _idNumber) {
        shares = _shares; // Initialize shares
        name = _name; // Initialize name
        salary = _salary; // Initialize salary
        idNumber = _idNumber; // Initialize idNumber
    }

    // View function to retrieve the number of shares owned by the employee
    function viewShares() public view returns (uint16) {
        return shares;
    }

    // View function to retrieve the monthly salary of the employee
    function viewSalary() public view returns (uint32) {
        return salary;
    }

    // Custom error declaration
    error TooManyShares(uint16 _shares);

    // Function to grant additional shares to the employee
    function grantShares(uint16 _newShares) public {
        // Check if the requested shares exceed the limit
        if (_newShares > 5000) {
            revert("Too many shares"); // Revert with error message
        } else if (shares + _newShares > 5000) {
            revert TooManyShares(shares + _newShares); // Revert with custom error message
        }
        shares += _newShares; // Grant the new shares
    }

    // Function used for testing packing of storage variables (not relevant to main functionality)
    function checkForPacking(uint _slot) public view returns (uint r) {
        assembly {
            r := sload(_slot) // ✅ fixed: no space between sload and ()
        }
    }

    // Function to reset shares for debugging purposes (not relevant to main functionality)
    function debugResetShares() public {
        shares = 1000; // Reset shares to 1000
    }
}
