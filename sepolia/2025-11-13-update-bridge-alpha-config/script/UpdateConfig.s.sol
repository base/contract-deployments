// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Vm} from "forge-std/Vm.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {AddressAliasHelper} from "@eth-optimism-bedrock/src/vendor/AddressAliasHelper.sol";
import {ERC1967Factory} from "solady/utils/ERC1967Factory.sol";
import {ERC1967FactoryConstants} from "solady/utils/ERC1967FactoryConstants.sol";

interface IOptimismPortal2 {
    function depositTransaction(address _to, uint256 _value, uint64 _gasLimit, bool _isCreation, bytes memory _data)
        external
        payable;
}

interface IBridgeValidator {
    function reinitialize(uint256 partnerThreshold, address newOwner) external;
}

contract UpdateConfig is MultisigScript {
    using AddressAliasHelper for address;

    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address public immutable L1_PORTAL = vm.envAddress("L1_PORTAL");
    address public immutable L2_BRIDGE_VALIDATOR_PROXY = vm.envAddress("L2_BRIDGE_VALIDATOR_PROXY");
    address public immutable L2_BRIDGE_VALIDATOR_IMPL = vm.envAddress("L2_BRIDGE_VALIDATOR_IMPL");
    uint256 public immutable PARTNER_THRESHOLD = vm.envUint("PARTNER_THRESHOLD");
    address public immutable BRIDGE_VALIDATOR_OWNER = vm.envAddress("BRIDGE_VALIDATOR_OWNER");


    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        bytes memory innerData = abi.encodeCall(
            IBridgeValidator.reinitialize, (PARTNER_THRESHOLD, BRIDGE_VALIDATOR_OWNER.applyL1ToL2Alias())
        );

        address to = ERC1967FactoryConstants.ADDRESS;
        uint256 value = 0;
        uint64 gasLimit = 100_000;
        bool isCreation = false;
        bytes memory data = abi.encodeCall(
            ERC1967Factory.upgradeAndCall, (L2_BRIDGE_VALIDATOR_PROXY, L2_BRIDGE_VALIDATOR_IMPL, innerData)
        );

        calls[0] = IMulticall3.Call3Value({
            target: L1_PORTAL,
            allowFailure: false,
            callData: abi.encodeCall(IOptimismPortal2.depositTransaction, (to, value, gasLimit, isCreation, data)),
            value: value
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
