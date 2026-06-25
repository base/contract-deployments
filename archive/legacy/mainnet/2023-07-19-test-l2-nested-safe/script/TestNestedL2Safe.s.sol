// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";

contract TestNestedL2Safe is NestedMultisigBuilder {
    // ProxyAdminContract owned by the Nested L2 Safe
    address constant internal PROXY_ADMIN_CONTRACT = 0x4A466E4a2b5106bD7f2d3B39d35ded2ACDF491a2;
    // An example proxy contract which originally points to the old implementation
    address constant internal PROXY_CONTRACT = 0xEACccF3894Ef189A29a557F1B533932bf1ad8d11;
    // Existing implementation contract for the proxy
    address constant internal OLD_IMPLEMENTATION = 0x37AbE6b9174403C0BAA9909D0D02aa50e6C06FA7;
    // Implementation contract we want to upgrade to
    address constant internal NEW_IMPLEMENTATION = 0xf71368e2D4664feBe17b120dcB9e53289e0b9D1D;
    // Safe we're testing, which is the owner of the Proxy contract
    address constant internal NESTED_L2_SAFE = 0x2304CB33d95999dC29f4CeF1e35065e670a70050;

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);

        // Check contract was upgraded
        require(
            proxyAdmin.getProxyImplementation(PROXY_CONTRACT) == NEW_IMPLEMENTATION,
            "TestNestedL2Safe: implementation did not get set"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);
        require(
            proxyAdmin.getProxyImplementation(PROXY_CONTRACT) == OLD_IMPLEMENTATION,
            "TestNestedL2Safe: implementation did not get set"
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
        return NESTED_L2_SAFE;
    }
}