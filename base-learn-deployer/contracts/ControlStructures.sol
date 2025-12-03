// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ControlStructures {
    // Define custom errors for use within the contract
    error AfterHours(uint256 time);
    error AtLunch();

    // Function to determine the response based on the input number
    function fizzBuzz(uint256 _number) public pure returns (string memory response) {
        // Check if the number is divisible by both 3 and 5
        if (_number % 3 == 0 && _number % 5 == 0) {
            return "FizzBuzz"; // Return "FizzBuzz" if divisible by both 3 and 5
        }
        // Check if the number is divisible by 3
        else if (_number % 3 == 0) {
            return "Fizz"; // Return "Fizz" if divisible by 3
        }
        // Check if the number is divisible by 5
        else if (_number % 5 == 0) {
            return "Buzz"; // Return "Buzz" if divisible by 5
        }
        // If none of the above conditions are met
        else {
            return "Splat"; // Return "Splat" if none of the conditions are met
        }
    }

    // Function to determine the response based on the input time
    function doNotDisturb(uint256 _time) public pure returns (string memory result) {
        // Ensure the input time is within valid bounds (less than 2400)
        assert(_time < 2400);

        // Check different time ranges and return appropriate responses or revert with errors
        if (_time > 2200 || _time < 800) {
            revert AfterHours(_time); // Revert with custom error if it's after 10:00 PM or before 8:00 AM
        }
        else if (_time >= 1200 && _time <= 1299) {
            revert AtLunch(); // Revert with custom error if it's between 12:00 PM and 1:00 PM
        }
        else if (_time >= 800 && _time <= 1199) {
            return "Morning!"; // Return "Morning!" if it's between 8:00 AM and 11:59 AM
        }
        else if (_time >= 1300 && _time <= 1799) {
            return "Afternoon!"; // Return "Afternoon!" if it's between 1:00 PM and 5:59 PM
        }
        else if (_time >= 1800 && _time <= 2200) {
            return "Evening!"; // Return "Evening!" if it's between 6:00 PM and 10:00 PM
        }
    }
}
