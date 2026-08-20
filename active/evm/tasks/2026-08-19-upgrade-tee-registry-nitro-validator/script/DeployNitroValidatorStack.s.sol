// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";

import {CertManager} from "nitro-validator/src/CertManager.sol";
import {NitroValidator} from "nitro-validator/src/NitroValidator.sol";
import {P384Verifier} from "nitro-validator/src/P384Verifier.sol";

/// @notice Deploys the hinted Nitro validator stack and records its addresses.
contract DeployNitroValidatorStack is Script {
    address internal immutable certManagerOwner;
    address internal immutable certManagerRevoker;
    string internal addressesJson;

    P384Verifier public p384Verifier;
    CertManager public certManager;
    NitroValidator public nitroValidator;

    constructor() {
        certManagerOwner = vm.envAddress("CERT_MANAGER_OWNER");
        certManagerRevoker = vm.envAddress("CERT_MANAGER_REVOKER");
        addressesJson = vm.envString("ADDRESSES_JSON");
    }

    function setUp() public view {
        require(certManagerOwner != address(0), "cert manager owner not set");
        require(certManagerRevoker != address(0), "cert manager revoker not set");
    }

    function run() external {
        vm.startBroadcast();

        p384Verifier = new P384Verifier();
        certManager = new CertManager({
            p384Verifier_: p384Verifier, initialOwner: certManagerOwner, initialRevoker: certManagerRevoker
        });
        nitroValidator = new NitroValidator({_certManager: certManager, _p384Verifier: p384Verifier});

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        require(address(p384Verifier).code.length != 0, "p384 verifier not deployed");
        require(address(certManager).code.length != 0, "cert manager not deployed");
        require(address(nitroValidator).code.length != 0, "nitro validator not deployed");
        require(address(certManager.p384Verifier()) == address(p384Verifier), "cert manager p384 mismatch");
        require(certManager.owner() == certManagerOwner, "cert manager owner mismatch");
        require(certManager.revoker() == certManagerRevoker, "cert manager revoker mismatch");
        require(certManager.verified(certManager.ROOT_CA_CERT_HASH()).length != 0, "root certificate not cached");
        require(address(nitroValidator.certManager()) == address(certManager), "validator cert manager mismatch");
        require(address(nitroValidator.p384Verifier()) == address(p384Verifier), "validator p384 mismatch");
    }

    function _writeAddresses() internal {
        console.log("P384Verifier:", address(p384Verifier));
        console.log("CertManager:", address(certManager));
        console.log("NitroValidator:", address(nitroValidator));

        string memory root = "root";
        vm.serializeAddress(root, "p384Verifier", address(p384Verifier));
        vm.serializeAddress(root, "certManager", address(certManager));
        string memory json = vm.serializeAddress(root, "nitroValidator", address(nitroValidator));
        vm.writeJson(json, addressesJson);
    }
}
