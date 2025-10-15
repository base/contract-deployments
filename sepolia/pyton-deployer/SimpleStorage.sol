// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 public value;
    event Set(uint256 newValue);

    function set(uint256 _v) public {
        value = _v;
        emit Set(_v);
    }
}
