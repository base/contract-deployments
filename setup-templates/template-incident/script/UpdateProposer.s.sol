// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/src/universal/ProxyAdmin.sol";
import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

/**
 * @title UpdateProposer
 * @notice Script to update the L2OutputOracle implementation contract
 * @dev This script requires the following environment variables to be set:
 * - L1_PROXY_ADMIN: Address of the ProxyAdmin contract that manages the L2OutputOracle proxy
 * - L1_NESTED_SAFE: Address of the nested safe that owns the ProxyAdmin
 * - L2_OUTPUT_PROPOSER: Address of the L2OutputOracle proxy contract
 * - L2_OUTPUT_PROPOSER_NEW_IMPL: Address of the new L2OutputOracle implementation
 */
contract UpdateProposer is NestedMultisigBuilder {
    // Note: A new L2OutputOracle implementation contract must be deployed first
    // See SetupNewProposer.s.sol for deployment of new implementation

    // ProxyAdmin contract that manages the upgradeability of the L2OutputOracle
    address internal PROXY_ADMIN_CONTRACT = vm.envAddress("L1_PROXY_ADMIN");
    
    // Owner of the ProxyAdmin contract (typically a nested safe)
    address internal PROXY_ADMIN_OWNER = vm.envAddress("L1_NESTED_SAFE");
    
    // Current L2OutputOracle proxy contract address
    address internal L2_OUTPUT_PROPOSER = vm.envAddress("L2_OUTPUT_PROPOSER");
    
    // Address of the new L2OutputOracle implementation contract
    address internal L2_OUTPUT_PROPOSER_NEW_IMPL = vm.envAddress("L2_OUTPUT_PROPOSER_NEW_IMPL");

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);
        require(proxyAdmin.getProxyImplementation(L2_OUTPUT_PROPOSER).codehash == L2_OUTPUT_PROPOSER_NEW_IMPL.codehash);
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: PROXY_ADMIN_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(L2_OUTPUT_PROPOSER), L2_OUTPUT_PROPOSER_NEW_IMPL)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return PROXY_ADMIN_OWNER;
    }
}
