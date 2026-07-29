// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@base-contracts/script/universal/MultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";

contract TestL2Safe is MultisigBuilder {
    address constant internal PROXY_ADMIN_CONTRACT = 0x21EB1F4C0b15336b83Ec574842C1fcfC9DF6d698;
    address constant internal PROXY_CONTRACT = 0xCFf6EbA9DD666C6AE51Ec35a3999A9715e5aAa87;
    address constant internal OLD_IMPLEMENTATION = 0x0a9F0F5B38951955ff68263510AD45Af71468D55;
    address constant internal NEW_IMPLEMENTATION = 0x004BC95c786dc50b42cC573458cC39ba82d98C09;
    address constant internal L2_SAFE = 0xd94E416cf2c7167608B2515B7e4102B41efff94f;

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);

        // Check contract was upgraded
        require(
            proxyAdmin.getProxyImplementation(PROXY_CONTRACT) == NEW_IMPLEMENTATION,
            "TestL2Safe: implementation did not get set"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);
        require(
            proxyAdmin.getProxyImplementation(PROXY_CONTRACT) == OLD_IMPLEMENTATION,
            "TestL2Safe: implementation did not get set"
        );

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        // Upgrade a contract implementation
        calls[0] = IMulticall3.Call3({
            target: PROXY_ADMIN_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(PROXY_CONTRACT), NEW_IMPLEMENTATION)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return L2_SAFE;
    }
}