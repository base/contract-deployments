// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/L1/L1StandardBridge.sol";
import "forge-std/Script.sol";

contract DeployL1StandardBridgeImplementation is Script {
    address internal DEPLOYER = 0x24A1704636AB7083eaC56294aFF13e1651997638;
    address internal L1_STANDARD_BRIDGE_PROXY = vm.envAddress("L1_STANDARD_BRIDGE_PROXY");

    function implSalt() public returns (bytes32) {
        return keccak256(bytes(vm.envOr("IMPL_SALT", string("allyourbasearebelongtoyou"))));
    }

    function run() public {
        L1StandardBridge proxy = L1StandardBridge(payable(L1_STANDARD_BRIDGE_PROXY));

        CrossDomainMessenger messenger = proxy.messenger();
        console.log("Current L1CrossDomainMessenger value: %s", address(messenger));

        string memory version = proxy.version();
        console.log("Current L1StandardBridge version: %s", version);

        vm.broadcast(DEPLOYER);
        L1StandardBridge bridge = new L1StandardBridge{ salt: implSalt() }();
        console.log("New L1StandardBridge deployed at %s", address(bridge));

        version = bridge.version();
        console.log("New L1StandardBridge version: %s", version);

        require(address(bridge.MESSENGER()) == address(0));
        require(address(bridge.messenger()) == address(0));
        require(address(bridge.OTHER_BRIDGE()) == Predeploys.L2_STANDARD_BRIDGE);
        require(address(bridge.otherBridge()) == Predeploys.L2_STANDARD_BRIDGE);
    }
}
