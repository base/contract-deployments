// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console} from "forge-std/Script.sol";

import {BaseFeeVault} from "@base-contracts/src/L2/BaseFeeVault.sol";
import {L1FeeVault} from "@base-contracts/src/L2/L1FeeVault.sol";
import {SequencerFeeVault} from "@base-contracts/src/L2/SequencerFeeVault.sol";

/// @notice Deploys the SequencerFeeVault, BaseFeeVault and L1FeeVault implementations on L2. Their constructor
///         disables initializers, so the proxies are initialized by `UpgradeL2Predeploys`.
contract DeployFeeVaultImpls is Script {
    string internal constant FEE_VAULT_VERSION = "1.6.0";

    // Deployment output written to addresses.json.
    address public sequencerFeeVault;
    address public baseFeeVault;
    address public l1FeeVault;

    function run() external {
        vm.startBroadcast();

        sequencerFeeVault = address(new SequencerFeeVault());
        baseFeeVault = address(new BaseFeeVault());
        l1FeeVault = address(new L1FeeVault());

        vm.stopBroadcast();

        require(
            _eq(SequencerFeeVault(payable(sequencerFeeVault)).version(), FEE_VAULT_VERSION),
            "sequencer fee vault version mismatch"
        );
        require(
            _eq(BaseFeeVault(payable(baseFeeVault)).version(), FEE_VAULT_VERSION), "base fee vault version mismatch"
        );
        require(_eq(L1FeeVault(payable(l1FeeVault)).version(), FEE_VAULT_VERSION), "l1 fee vault version mismatch");

        console.log("SequencerFeeVault:", sequencerFeeVault);
        console.log("BaseFeeVault:", baseFeeVault);
        console.log("L1FeeVault:", l1FeeVault);

        string memory path = vm.envString("ADDRESSES_JSON");
        vm.writeJson(vm.toString(sequencerFeeVault), path, ".sequencerFeeVault");
        vm.writeJson(vm.toString(baseFeeVault), path, ".baseFeeVault");
        vm.writeJson(vm.toString(l1FeeVault), path, ".l1FeeVault");
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
