// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ErrorTriageExercise {
    /**
     * @dev Finds the difference between each uint with its neighbor (a to b, b to c, etc.)
     * and returns a uint array with the absolute integer difference of each pairing.
     *
     * @param _a The first unsigned integer.
     * @param _b The second unsigned integer.
     * @param _c The third unsigned integer.
     * @param _d The fourth unsigned integer.
     *
     * @return results An array containing the absolute differences between each pair of integers.
     */
    function diffWithNeighbor(
        uint _a,
        uint _b,
        uint _c,
        uint _d
    ) public pure returns (uint[] memory) {
        // Initialize an array to store the differences
        uint[] memory results = new uint[](3);

        // Calculate the absolute difference between each pair of integers and store it in the results array
        results[0] = _a > _b ? _a - _b : _b - _a;
        results[1] = _b > _c ? _b - _c : _c - _b;
        results[2] = _c > _d ? _c - _d : _d - _c;

        // Return the array of differences
        return results;
    }

    /**
     * @dev Changes the base by the value of the modifier. Base is always >= 1000. Modifiers can be
     * between positive and negative 100.
     *
     * @param _base The base value to be modified.
     * @param _modifier The value by which the base should be modified.
     *
     * @return returnValue The modified value of the base.
     */
    function applyModifier(
        uint _base,
        int _modifier
    ) public pure returns (uint returnValue) {
        // Apply the modifier to the base value
        if(_modifier > 0) {
            return _base + uint(_modifier);
        }
        return _base - uint(-_modifier);
    }

    uint[] arr;

    function popWithReturn() public returns (uint returnNum) {
        if(arr.length > 0) {
            uint result = arr[arr.length - 1];
            arr.pop();
            return result;
        }
    }

    // The utility functions below are working as expected
    function addToArr(uint _num) public {
        arr.push(_num);
    }

    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    function resetArr() public {
        delete arr;
    }
}
