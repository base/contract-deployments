// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IMulticall3 } from "forge-std/interfaces/IMulticall3.sol";
import { SystemConfig } from "@eth-optimism-bedrock/contracts/L1/SystemConfig.sol";
import { MultisigBuilder } from "@base-contracts/script/universal/MultisigBuilder.sol";

contract TransferSystemConfigOwner is MultisigBuilder {
    address constant internal SYSTEM_CONFIG_ADDR = 0x73a79Fab69143498Ed3712e519A88a918e1f4072;
    address constant internal NEW_OWNER = 0x14536667Cd30e52C0b458BaACcB9faDA7046E056;
    address constant internal CB_OWNER_SAFE = 0x9855054731540A48b28990B63DcF4f33d8AE46A1;

    /**
     * @notice Follow up assertions to ensure that the script ran to completion.
     */
    function _postCheck() internal override view {
        require(OwnableUpgradeable(SYSTEM_CONFIG_ADDR).owner() == NEW_OWNER, "Owner did not change");
    }

    /**
     * @notice Returns the safe address to execute the transaction from
     */
    function _ownerSafe() internal override view returns (address) {
        return CB_OWNER_SAFE;
    }

    /**
     * @notice Creates the calldata
     */
    function _buildCalls() internal override pure returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: SYSTEM_CONFIG_ADDR,
            allowFailure: false,
            callData: abi.encodeCall(
                OwnableUpgradeable.transferOwnership,
                (NEW_OWNER)
            )
        });

        return calls;
    }
}
