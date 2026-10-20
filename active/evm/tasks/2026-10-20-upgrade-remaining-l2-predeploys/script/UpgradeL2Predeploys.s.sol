// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm, VmSafe} from "forge-std/Vm.sol";
import {IOptimismPortal2} from "interfaces/L1/IOptimismPortal2.sol";
import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {L2Upgrade} from "./L2Upgrade.sol";

contract UpgradeL2Predeploys is MultisigScript, L2Upgrade {
    address internal immutable optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
    address internal immutable factoryImpl = vm.envAddress("ERC721_FACTORY_IMPL");
    address internal immutable vaultImpl = vm.envAddress("OPERATOR_FEE_VAULT_IMPL");
    address internal immutable registryImpl = vm.envAddress("SCHEMA_REGISTRY_IMPL");
    address internal immutable easImpl = vm.envAddress("EAS_IMPL");
    string internal l2RpcUrl = vm.envString("L2_RPC_URL");

    function setUp() public view {
        require(block.chainid == 11155111, "Sepolia L1 only");
        require(!IOptimismPortal2(payable(optimismPortal)).paused(), "optimism portal paused");
        require(factoryBridge != address(0) && vaultRecipient != address(0), "missing configuration");
        require(vaultNetwork <= 1 && remoteChainId == block.chainid, "invalid network configuration");
    }

    function _implementations() internal view returns (address[4] memory) {
        return [factoryImpl, vaultImpl, registryImpl, easImpl];
    }

    function _buildCalls() internal view override returns (Call[] memory calls) {
        bytes[] memory l2Calls = _l2Calls(_implementations());
        calls = new Call[](l2Calls.length);
        for (uint256 i; i < l2Calls.length; i++) {
            calls[i] = Call({
                operation: Enum.Operation.Call,
                target: optimismPortal,
                data: abi.encodeCall(IOptimismPortal2.depositTransaction, (ADMIN, 0, L2_GAS_LIMIT, false, l2Calls[i])),
                value: 0
            });
        }
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        uint256 deposits;
        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory access = accesses[i];
            if (access.kind != VmSafe.AccountAccessKind.Call || access.account != optimismPortal) continue;
            if (access.data.length < 4 || bytes4(access.data) != IOptimismPortal2.depositTransaction.selector) {
                continue;
            }
            require(access.accessor == ownerSafe && !access.reverted, "invalid deposit");
            deposits++;
        }
        require(deposits == 4, "unexpected deposit count");
        uint256 l1Fork = vm.activeFork();
        vm.createSelectFork(l2RpcUrl);
        require(block.chainid == 84532, "Base Sepolia L2 only");
        _replay(_implementations());
        vm.selectFork(l1Fork);
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
