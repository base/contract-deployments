// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {CBMulticall} from "@base-contracts/src/utils/CBMulticall.sol";

contract DeployCBMulticallScript is Script {
    bytes32 public constant SALT = bytes32(uint256(1));

    CBMulticall cbMulticall;

    function run() public {
        vm.startBroadcast();
        cbMulticall = new CBMulticall{salt: SALT}();
        console.log("CBMulticall deployed at: ", address(cbMulticall));
        vm.stopBroadcast();

        string memory obj = "root";
        string memory json = vm.serializeAddress(obj, "cbMulticall", address(cbMulticall));
        vm.writeJson(json, "addresses.json");

        _postCheck();
    }

    function _postCheck() internal view {
        vm.assertEq(
            address(cbMulticall),
            vm.computeCreate2Address({salt: SALT, initCodeHash: _initCodeHash(), deployer: CREATE2_FACTORY}),
            "The cbMulticall address does not match the one computed by `vm.computeCreate2Address`"
        );
    }

    function _initCode() private view returns (bytes memory) {
        bytes memory args = "";
        return abi.encodePacked(vm.getCode("CBMulticall.sol:CBMulticall"), args);
    }

    function _initCodeHash() private view returns (bytes32) {
        return keccak256(_initCode());
    }
}
