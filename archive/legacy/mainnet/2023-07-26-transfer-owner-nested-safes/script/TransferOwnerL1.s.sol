// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@base-contracts/script/universal/MultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";

contract TransferOwnerL1 is MultisigBuilder {
    address constant internal PROXY_CONTRACT = 0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E; 
    address constant internal OLD_OWNER = 0x9855054731540A48b28990B63DcF4f33d8AE46A1;
    address constant internal NEW_OWNER = 0x7bB41C3008B3f03FE483B28b8DB90e19Cf07595c;

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_CONTRACT);
        require(proxyAdmin.owner() == NEW_OWNER, "ProxyAdmin owner did not get updated");
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: PROXY_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                OwnableUpgradeable.transferOwnership,
                (NEW_OWNER)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return OLD_OWNER;
    }
}