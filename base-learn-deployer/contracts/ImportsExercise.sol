// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importing the SillyStringUtils library
import "./SillyStringUtils.sol";

contract ImportsExercise {
    // Using the SillyStringUtils library for string manipulation
    using SillyStringUtils for string;

    // Declaring a public variable to store a Haiku
    SillyStringUtils.Haiku public haiku;

    // Function to save a Haiku
    function saveHaiku(string memory _line1, string memory _line2, string memory _line3) public {
        haiku.line1 = _line1;
        haiku.line2 = _line2;
        haiku.line3 = _line3;
    }

    // Function to retrieve the saved Haiku
    function getHaiku() public view returns (SillyStringUtils.Haiku memory) {
        return haiku;
    }

    // Function to append a shrugging emoji to the third line of the Haiku
    function shruggieHaiku() public view returns (SillyStringUtils.Haiku memory) {
        // Creating a copy of the Haiku
        SillyStringUtils.Haiku memory newHaiku = haiku;
        // Appending the shrugging emoji to the third line using the shruggie function from the SillyStringUtils library
        newHaiku.line3 = newHaiku.line3.shruggie();
        return newHaiku;
    }
}
