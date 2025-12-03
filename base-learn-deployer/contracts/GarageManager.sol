// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GarageManager
 * @dev Contract to manage a garage of cars for each user
 */
contract GarageManager {
    // Mapping to store the garage of cars for each user
    mapping(address => Car[]) private garages;

    // Struct to represent a car
    struct Car {
        string make; // Make of the car
        string model; // Model of the car
        string color; // Color of the car
        uint numberOfDoors; // Number of doors of the car
    }

    // Custom error for handling invalid car index
    error BadCarIndex(uint256 index);

    /**
     * @dev Adds a new car to the caller's garage
     * @param _make The make of the car
     * @param _model The model of the car
     * @param _color The color of the car
     * @param _numberOfDoors The number of doors of the car
     */
    function addCar(string memory _make, string memory _model, string memory _color, uint _numberOfDoors) external {
        // Push a new car struct with the provided details to the caller's garage
        garages[msg.sender].push(Car(_make, _model, _color, _numberOfDoors));
    }

    /**
     * @dev Retrieves the caller's array of cars
     * @return An array of `Car` structs
     */
    function getMyCars() external view returns (Car[] memory) {
        // Return the array of cars stored in the caller's garage
        return garages[msg.sender];
    }

    /**
     * @dev Retrieves a specific user's array of cars
     * @param _user The address of the user
     * @return An array of `Car` structs
     */
    function getUserCars(address _user) external view returns (Car[] memory) {
        // Return the array of cars stored in the garage of the specified user
        return garages[_user];
    }

    /**
     * @dev Updates a specific car in the caller's garage
     * @param _index The index of the car in the garage array
     * @param _make The new make of the car
     * @param _model The new model of the car
     * @param _color The new color of the car
     * @param _numberOfDoors The new number of doors of the car
     */
    function updateCar(uint256 _index, string memory _make, string memory _model, string memory _color, uint _numberOfDoors) external {
        // Check if the provided index is valid
        if (_index >= garages[msg.sender].length) {
            revert BadCarIndex({index: _index}); // Revert with custom error if the index is invalid
        }
        // Update the specified car with the new details
        garages[msg.sender][_index] = Car(_make, _model, _color, _numberOfDoors);
    }

    /**
     * @dev Deletes all cars in the caller's garage
     */
    function resetMyGarage() external {
        // Delete all cars from the caller's garage
        delete garages[msg.sender];
    }
}
