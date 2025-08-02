// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script} from "forge-std/Script.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Recovery} from "@base-contracts/src/recovery/Recovery.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IOptimismPortal2} from "@eth-optimism-bedrock/interfaces/L1/IOptimismPortal2.sol";

struct AddressJsonRecoveryInfo {
    address refund_address;
    string addressType;
    string category;
    string totalWei;
}

contract OPStackExecuteRecovery is MultisigScript {
    address internal immutable OWNER_SAFE = vm.envAddress("INCIDENT_MULTISIG");
    address internal PORTAL = vm.envAddress("PORTAL");
    address internal immutable L2_RECOVERY_PROXY = vm.envAddress("RECOVERY_PROXY");

    uint256 internal immutable ADDRESS_INDEX = vm.envUint("ADDRESS_INDEX");

    address[] public addresses;
    uint256[] public amounts;

    function setUp() public {
        AddressJsonRecoveryInfo[] memory jsonAddressesToRefund;
        string memory root = vm.projectRoot();
        string memory path =
            string.concat(root, string.concat("/output/", vm.envString("CHAIN"), "/recovery_addresses.json"));
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json, ".addresses");
        jsonAddressesToRefund = abi.decode(data, (AddressJsonRecoveryInfo[]));

        uint256 numAddressesToProcess = 100;
        uint256 startingIndex = ADDRESS_INDEX * numAddressesToProcess;
        if (jsonAddressesToRefund.length - startingIndex < numAddressesToProcess) {
            numAddressesToProcess = jsonAddressesToRefund.length - startingIndex;
        }

        for (uint256 i; i < numAddressesToProcess; i++) {
            addresses.push(jsonAddressesToRefund[i + startingIndex].refund_address);
            amounts.push(vm.parseUint(jsonAddressesToRefund[i + startingIndex].totalWei));
        }
    }

    function _buildCalls() internal view virtual override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        address to = L2_RECOVERY_PROXY;
        uint256 value = 0;
        uint64 gasLimit = 2_000_000;
        bool isCreation = false;
        bytes memory data = abi.encodeCall(Recovery.withdrawETH, (addresses, amounts));

        calls[0] = IMulticall3.Call3Value({
            target: PORTAL,
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
