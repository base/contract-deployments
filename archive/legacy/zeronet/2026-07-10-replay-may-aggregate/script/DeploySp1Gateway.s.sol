// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {SP1VerifierGateway} from "sp1-contracts/src/SP1VerifierGateway.sol";
import {ISP1VerifierWithHash} from "sp1-contracts/src/ISP1Verifier.sol";

/// @notice Deploys a PROXY_ADMIN_OWNER-owned SP1 verifier gateway.
contract DeploySp1Gateway is Script {
    // Task config from .env.
    address internal immutable ownerSafeEnv = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable sp1VerifierRouteEnv = vm.envAddress("SP1_VERIFIER_ROUTE");

    // Derived route metadata used for post-checks before the route is added by PROXY_ADMIN_OWNER.
    bytes32 internal sp1VerifierHash;
    bytes4 internal sp1VerifierSelector;

    // Deployment output written to addresses.json.
    address public sp1VerifierGateway;

    function setUp() public {
        sp1VerifierHash = ISP1VerifierWithHash(sp1VerifierRouteEnv).VERIFIER_HASH();
        sp1VerifierSelector = bytes4(sp1VerifierHash);

        require(ownerSafeEnv != address(0), "owner safe not set");
        require(sp1VerifierRouteEnv != address(0), "sp1 verifier route not set");
        require(sp1VerifierHash != bytes32(0), "sp1 verifier hash not set");
        require(sp1VerifierSelector != bytes4(0), "sp1 verifier selector not set");
    }

    function run() external {
        vm.startBroadcast();

        sp1VerifierGateway = address(new SP1VerifierGateway(ownerSafeEnv));

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        SP1VerifierGateway gateway = SP1VerifierGateway(sp1VerifierGateway);
        (address verifier, bool frozen) = gateway.routes(sp1VerifierSelector);

        require(gateway.owner() == ownerSafeEnv, "sp1 gateway owner mismatch");
        require(verifier == address(0), "sp1 gateway route already set");
        require(!frozen, "sp1 gateway route unexpectedly frozen");
    }

    function _writeAddresses() internal {
        console.log("SP1VerifierGateway:", sp1VerifierGateway);

        vm.writeJson({json: vm.toString(sp1VerifierGateway), path: "addresses.json", valueKey: ".sp1VerifierGateway"});
    }
}
