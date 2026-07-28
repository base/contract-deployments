// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@base-contracts/script/universal/MultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";

contract TransferOwnerL2 is MultisigBuilder {
    address constant internal PROXY_CONTRACT = 0x4200000000000000000000000000000000000018; 
    address constant internal OLD_OWNER = 0xd94E416cf2c7167608B2515B7e4102B41efff94f;
    address constant internal NEW_OWNER = 0x2304CB33d95999dC29f4CeF1e35065e670a70050;

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