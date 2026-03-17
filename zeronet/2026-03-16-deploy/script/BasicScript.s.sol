// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";

contract BasicScript is Script {
    function setUp() public {}

    function run() public {
        _preCheck();
        // Do something
        _postCheck();
    }

    function _preCheck() private {}
    function _postCheck() private {}
}
