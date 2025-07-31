// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Recovery} from "@base-contracts/src/recovery/Recovery.sol";
import {Vm} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {IInbox} from "@aribtrum-classic/packages/arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";

struct AddressJsonRecoveryInfo {
    address address;
    string category;
    string totalWei;
    string addressType;
}

struct AddressRecoveryInfo {
    address refund_address;
    string category;
    uint256 total_eth;
}

interface IRecovery {
    function withdrawETH(address[] calldata targets, uint256[] calldata amounts) external;
}

contract ArbitrumExecuteRecovery is MultisigScript {
    address internal immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    address internal ARBITRUM_L1_DELAYED_INBOX = vm.envAddress("ARBITRUM_L1_DELAYED_INBOX");
    address internal immutable L2_RECOVERY_IMPLEMENTATION = vm.envAddress("RECOVERY_IMPLEMENTATION");

    AddressRecoveryInfo[] addressesToRefund;
    mapping(address => uint256) originalBalances;

    function setUp() public {
        AddressJsonRecoveryInfo[] memory jsonAddressesToRefund;
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/output/arbitrum/recovery_addresses.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json, ".addresses");
        jsonAddressesToRefund = abi.decode(data, (AddressJsonRecoveryInfo[]));

        for (uint256 i = 0; i < jsonAddressesToRefund.length; i = i + 1) {
            AddressRecoveryInfo memory refundInfo = AddressRecoveryInfo(
                jsonAddressesToRefund[i].address,
                jsonAddressesToRefund[i].category,
                vm.parseUint(jsonAddressesToRefund[i].totalWei)
            );
            addressesToRefund.push(refundInfo);

            originalBalances[jsonAddressesToRefund[i].address] = jsonAddressesToRefund[i].address.balance;
        }
    }

    function _buildCalls() internal view virtual override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](1);

        address[] memory addresses = new address[](addressesToRefund.length);
        uint256[] memory amounts = new uint256[](addressesToRefund.length);
        for (uint256 i = 0; i < addressesToRefund.length; i = i + 1) {
            addresses[i] = addressesToRefund[i].refund_address;
            amounts[i] = addressesToRefund[i].total_eth;
        }

        calls[0] = IMulticall3.Call3Value({
            target: ARBITRUM_L1_DELAYED_INBOX,
            allowFailure: false,
            callData: abi.encodeCall(
                IInbox.sendL1FundedContractTransaction,
                (
                    // gasprice were obtained using latest gas prices from public gas trackers on arbitrum.
                    // the maxgas was then derived by asking "how much ETH are we willing to spend to refund users?"
                    // and 0.02 ETH seemed a reasonable worst case cost.
                    1000000000, // maxgas
                    20000000, // gasPriceBid
                    L2_RECOVERY_IMPLEMENTATION,
                    abi.encodeCall(IRecovery.withdrawETH, (addresses, amounts))
                )
            ),
            value: 0
        });

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {}

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
