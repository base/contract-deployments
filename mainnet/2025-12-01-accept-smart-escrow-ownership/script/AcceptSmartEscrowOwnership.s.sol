// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";

contract AcceptSmartEscrowOwnership is MultisigScript {
    address internal immutable OWNER_SAFE;
    address internal immutable PORTAL;
    address internal immutable SMART_ESCROW;
    uint64 internal immutable L2_GAS_LIMIT;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        PORTAL = vm.envAddress("PORTAL");
        SMART_ESCROW = vm.envAddress("SMART_ESCROW");
        L2_GAS_LIMIT = uint64(vm.envUint("L2_GAS_LIMIT"));

        require(OWNER_SAFE != address(0), "OWNER_SAFE env var not set");
        require(PORTAL != address(0), "PORTAL env var not set");
        require(SMART_ESCROW != address(0), "SMART_ESCROW env var not set");
    }

    function setUp() public view {
        require(L2_GAS_LIMIT > 0, "L2_GAS_LIMIT must be > 0");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory calls) {
        calls = new IMulticall3.Call3Value[](1);

        address payable target = SMART_ESCROW;
        uint256 value = 0;
        uint64 gasLimit = L2_GAS_LIMIT;
        bool isCreation = false;
        bytes memory acceptData = abi.encodeCall(AccessControlDefaultAdminRules.acceptDefaultAdminTransfer, ());

        calls[0] = IMulticall3.Call3Value({
            target: PORTAL,
            allowFailure: false,
            callData: abi.encodeCall(
                IOptimismPortal2.depositTransaction, (target, value, gasLimit, isCreation, acceptData)
            ),
            value: 0
        });
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
