// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BasicMath {
    uint256 constant MAX_INT = type(uint256).max;

    function adder(uint256 _a, uint256 _b) external pure returns (uint256 sum, bool error) {
        if (_b > MAX_INT - _a) {
            return (0, true); // Overflow occurred
        }
        return (_a + _b, false);
    }

    function subtractor(uint256 _a, uint256 _b) external pure returns (uint256 difference, bool error) {
        if (_b > _a) {
            return (0, true); // Underflow occurred
        }
        return (_a - _b, false);
    }
}
