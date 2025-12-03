// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FavoriteRecords
 * @dev Contract to manage a list of approved music records and allow users to add them to their favorites
 */
contract FavoriteRecords {
    // Mapping to store whether a record is approved
    mapping(string => bool) private approvedRecords;
    // Array to store the index of approved records
    string[] private approvedRecordsIndex;

    // Mapping to store user's favorite records
    mapping(address => mapping(string => bool)) public userFavorites;
    // Mapping to store the index of user's favorite records
    mapping(address => string[]) private userFavoritesIndex;

    // Custom error to handle unapproved records
    error NotApproved(string albumName);

    /**
     * @dev Constructor that initializes the approved records list
     */
    constructor() {
        // Predefined list of approved records
        approvedRecordsIndex = [
            "Thriller",
            "Back in Black",
            "The Bodyguard",
            "The Dark Side of the Moon",
            "Their Greatest Hits (1971-1975)",
            "Hotel California",
            "Come On Over",
            "Rumours",
            "Saturday Night Fever"
        ];
        // Initialize the approved records mapping
        for (uint i = 0; i < approvedRecordsIndex.length; i++) {
            approvedRecords[approvedRecordsIndex[i]] = true;
        }
    }

    /**
     * @dev Returns the list of approved records
     * @return An array of approved record names
     */
    function getApprovedRecords() public view returns (string[] memory) {
        return approvedRecordsIndex;
    }

    /**
     * @dev Adds an approved record to the user's favorites
     * @param _albumName The name of the album to be added
     */
    function addRecord(string memory _albumName) public {
        // Check if the record is approved
        if (!approvedRecords[_albumName]) {
            revert NotApproved({albumName: _albumName});
        }
        // Check if the record is not already in the user's favorites
        if (!userFavorites[msg.sender][_albumName]) {
            // Add the record to the user's favorites
            userFavorites[msg.sender][_albumName] = true;
            // Add the record to the user's favorites index
            userFavoritesIndex[msg.sender].push(_albumName);
        }
    }

    /**
     * @dev Returns the list of a user's favorite records
     * @param _address The address of the user
     * @return An array of user's favorite record names
     */
    function getUserFavorites(address _address) public view returns (string[] memory) {
        return userFavoritesIndex[_address];
    }

    /**
     * @dev Resets the caller's list of favorite records
     */
    function resetUserFavorites() public {
        // Iterate through the user's favorite records
        for (uint i = 0; i < userFavoritesIndex[msg.sender].length; i++) {
            // Delete each record from the user's favorites mapping
            delete userFavorites[msg.sender][userFavoritesIndex[msg.sender][i]];
        }
        // Delete the user's favorites index
        delete userFavoritesIndex[msg.sender];
    }
}
