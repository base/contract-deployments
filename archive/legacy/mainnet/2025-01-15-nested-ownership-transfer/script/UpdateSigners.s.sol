// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigBuilder} from "@base-contracts/script/universal/MultisigBuilder.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";
import {OwnerManager} from "safe-smart-account/contracts/base/OwnerManager.sol";

// Adds `SAFE_A` and `SAFE_B` as owners to `OWNER_SAFE` and sets threshold to 2
// `SAFE_A` should have same owners as `OWNER_SAFE`
// `SAFE_A` should have same threshold as `OWNER_SAFE`
// `SAFE_B` should be a 7-of-10 multisig
contract UpdateSigners is MultisigBuilder {
    using stdJson for string;

    address payable private SAFE_A;
    address payable private SAFE_B;

    uint256 internal constant THRESHOLD = 2;
    address payable internal OWNER_SAFE = payable(vm.envAddress("OWNER_SAFE"));
    string private ADDRESSES;

    address[] private A_OWNERS;
    address[] private B_OWNERS;

    uint256 private A_THRESHOLD;
    uint256 private B_THRESHOLD;

    function setUp() public {
        string memory rootPath = vm.projectRoot();
        string memory path = string.concat(rootPath, "/addresses.json");
        ADDRESSES = vm.readFile(path);

        SAFE_A = payable(ADDRESSES.readAddress(".SafeA"));
        SAFE_B = payable(ADDRESSES.readAddress(".SafeB"));

        A_OWNERS = Safe(SAFE_A).getOwners();
        A_THRESHOLD = Safe(SAFE_A).getThreshold();

        require(A_OWNERS.length == 6, "A owners length must be 6");
        require(A_THRESHOLD == 3, "A threshold must be 3");

        B_OWNERS = Safe(SAFE_B).getOwners();
        B_THRESHOLD = Safe(SAFE_B).getThreshold();

        require(B_OWNERS.length == 10, "B owners length must be 10");
        require(B_THRESHOLD == 7, "B threshold must be 7");

        address[] memory ownerSafeOwners = Safe(OWNER_SAFE).getOwners();
        uint256 ownerSafeThreshold = Safe(OWNER_SAFE).getThreshold();

        require(ownerSafeOwners.length == A_OWNERS.length, "Precheck owner count mismatch - A");
        require(ownerSafeThreshold == A_THRESHOLD, "Precheck threshold mismatch - A");
        for (uint256 i; i < ownerSafeOwners.length; i++) {
            require(ownerSafeOwners[i] == A_OWNERS[i], "Precheck owner mismatch - A");
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        address[] memory aOwners = Safe(SAFE_A).getOwners();
        address[] memory bOwners = Safe(SAFE_B).getOwners();

        uint256 aThreshold = Safe(SAFE_A).getThreshold();
        uint256 bThreshold = Safe(SAFE_B).getThreshold();

        address[] memory ownerSafeOwners = Safe(OWNER_SAFE).getOwners();

        uint256 ownerSafeThreshold = Safe(OWNER_SAFE).getThreshold();

        require(aThreshold == A_THRESHOLD, "Postcheck new signer threshold mismatch - A");
        require(bThreshold == B_THRESHOLD, "Postcheck new signer threshold mismatch - B");

        require(aOwners.length == A_OWNERS.length, "Postcheck length mismatch - A");
        require(bOwners.length == B_OWNERS.length, "Postcheck length mismatch - B");

        require(ownerSafeThreshold == THRESHOLD, "Postcheck owner threshold mismatch");
        require(ownerSafeOwners.length == 2, "Postcheck owner count mismatch");

        require(ownerSafeOwners[0] == SAFE_B, "Postcheck new signer mismatch - B");
        require(ownerSafeOwners[1] == SAFE_A, "Postcheck new signer mismatch - A");

        for (uint256 i; i < aOwners.length; i++) {
            require(aOwners[i] == A_OWNERS[i], "PostCheck 5");
        }

        for (uint256 i; i < bOwners.length; i++) {
            require(bOwners[i] == B_OWNERS[i], "PostCheck 6");
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2 + A_OWNERS.length);

        calls[0] = IMulticall3.Call3({
            target: OWNER_SAFE,
            allowFailure: false,
            callData: abi.encodeCall(OwnerManager.addOwnerWithThreshold, (SAFE_A, THRESHOLD))
        });
        calls[1] = IMulticall3.Call3({
            target: OWNER_SAFE,
            allowFailure: false,
            callData: abi.encodeCall(OwnerManager.addOwnerWithThreshold, (SAFE_B, THRESHOLD))
        });

        address prevOwner = SAFE_A;

        for (uint256 i; i < A_OWNERS.length; i++) {
            calls[2 + i] = IMulticall3.Call3({
                target: OWNER_SAFE,
                allowFailure: false,
                callData: abi.encodeCall(OwnerManager.removeOwner, (prevOwner, A_OWNERS[i], THRESHOLD))
            });
        }

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
