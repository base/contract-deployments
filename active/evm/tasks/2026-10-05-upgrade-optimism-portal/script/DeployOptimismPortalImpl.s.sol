// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";

/// @notice Deploys the OptimismPortal2 6.0.1 implementation.
/// @dev Built from base/contracts at BASE_CONTRACTS_COMMIT with patch/optimism-portal-6.0.1.patch
///      applied by `make deps`. Run it with `make TASK_NETWORK=<network> deploy`.
contract DeployOptimismPortalImpl is Script {
    string internal constant EXPECTED_VERSION = "6.0.1";

    address internal immutable optimismPortal;
    /// @dev Copied from the live portal so the redeploy cannot change the delay.
    uint256 internal immutable proofMaturityDelaySeconds;
    string internal addressesJson;

    OptimismPortal2 public optimismPortalImpl;

    constructor() {
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        addressesJson = vm.envString("ADDRESSES_JSON");
        require(optimismPortal.code.length != 0, "optimism portal not deployed");
        proofMaturityDelaySeconds = OptimismPortal2(payable(optimismPortal)).proofMaturityDelaySeconds();
    }

    function run() external {
        vm.startBroadcast();
        optimismPortalImpl = new OptimismPortal2(proofMaturityDelaySeconds);
        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(address(optimismPortalImpl).code.length != 0, "portal implementation not deployed");
        require(
            keccak256(bytes(optimismPortalImpl.version())) == keccak256(bytes(EXPECTED_VERSION)),
            "portal version mismatch"
        );
        require(
            optimismPortalImpl.proofMaturityDelaySeconds() == proofMaturityDelaySeconds, "portal proof delay mismatch"
        );
    }

    function _writeAddresses() internal {
        console.log("OptimismPortal2 impl:", address(optimismPortalImpl));

        vm.writeJson(vm.toString(address(optimismPortalImpl)), addressesJson, ".optimismPortalImpl");
        vm.writeJson(
            vm.toString(abi.encode(proofMaturityDelaySeconds)), addressesJson, ".optimismPortalImplConstructorArgs"
        );
    }
}
