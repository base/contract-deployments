// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {Vm} from "forge-std/Vm.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Recovery} from "@base-contracts/src/recovery/Recovery.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IInbox} from "nitro-contracts/bridge/IInbox.sol";

struct AddressJsonRecoveryInfo {
    address refund_address;
    string addressType;
    string category;
    string totalWei;
}

contract ArbitrumExecuteRecovery is MultisigScript {
    address internal immutable OWNER_SAFE = vm.envAddress("INCIDENT_MULTISIG");
    address internal ARBITRUM_INBOX = vm.envAddress("ARBITRUM_INBOX");
    address internal immutable L2_RECOVERY_PROXY = vm.envAddress("RECOVERY_PROXY");

    uint256 internal immutable ADDRESS_INDEX = vm.envUint("ADDRESS_INDEX");

    address[] public addresses;
    uint256[] public amounts;

    function setUp() public {
        AddressJsonRecoveryInfo[] memory jsonAddressesToRefund;
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/output/arbitrum/recovery_addresses.json");
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

        bytes memory data = abi.encodeCall(Recovery.withdrawETH, (addresses, amounts));

        uint256 l2CallValue = 0;
        uint256 maxSubmissionCost = 0.001 ether; // Estimated value
        uint256 gasLimit = 2_000_000;
        uint256 maxFeePerGas = 2 gwei;

        uint256 value = maxSubmissionCost + l2CallValue + (gasLimit * maxFeePerGas);

        calls[0] = IMulticall3.Call3Value({
            target: ARBITRUM_INBOX,
            allowFailure: false,
            callData: abi.encodeCall(
                IInbox.createRetryableTicket,
                (
                    L2_RECOVERY_PROXY, // to
                    l2CallValue,
                    maxSubmissionCost,
                    OWNER_SAFE, // excessFeeRefundAddress
                    OWNER_SAFE, // callValueRefundAddress
                    gasLimit,
                    maxFeePerGas,
                    data
                )
            ),
            value: value
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
