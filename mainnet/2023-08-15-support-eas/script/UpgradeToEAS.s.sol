// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

contract UpgradeToEAS is NestedMultisigBuilder {
    address constant internal PROXY_ADMIN_CONTRACT = 0x4200000000000000000000000000000000000018;
    address constant internal PROXY_ADMIN_OWNER = 0x4c7C99555e8afac3571c7456448021239F5b73bA;
    address constant internal SCHEMA_REGISTRY_PROXY = 0x4200000000000000000000000000000000000020;
    address constant internal EAS_PROXY = 0x4200000000000000000000000000000000000021;
    address constant internal SCHEMA_REGISTRY_IMPLEMENTATION = 0x919Cd6e9098dA2B7E0F8c31C45d60187492aad2b;
    address constant internal EAS_IMPLEMENTATION = 0x4dB6F244b68F152f06986601A6e467eC0Db90329;

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);
        require(proxyAdmin.getProxyImplementation(SCHEMA_REGISTRY_PROXY).codehash == SCHEMA_REGISTRY_IMPLEMENTATION.codehash);
        require(proxyAdmin.getProxyImplementation(EAS_PROXY).codehash == EAS_IMPLEMENTATION.codehash);
    }


    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](2);

        calls[0] = IMulticall3.Call3({
            target: PROXY_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(SCHEMA_REGISTRY_PROXY), SCHEMA_REGISTRY_IMPLEMENTATION)
            )
        });

        calls[1] = IMulticall3.Call3({
            target: PROXY_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(EAS_PROXY), EAS_IMPLEMENTATION)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return PROXY_ADMIN_OWNER;
    }
}