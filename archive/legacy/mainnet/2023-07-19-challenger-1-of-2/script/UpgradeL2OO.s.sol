// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/L1/L2OutputOracle.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@base-contracts/script/universal/MultisigBuilder.sol";

contract UpgradeL2OutputOracle is MultisigBuilder {
    address constant internal PROXY_ADMIN_CONTRACT = 0x0475cBCAebd9CE8AfA5025828d5b98DFb67E059E;
    address constant internal PROXY_ADMIN_OWNER = 0x9855054731540A48b28990B63DcF4f33d8AE46A1; // Current L1 contract owner
    address constant internal L2_OUTPUT_ORACLE_PROXY = 0x56315b90c40730925ec5485cf004d835058518A0;
    address constant internal NEW_IMPLEMENTATION = 0xf2460D3433475C8008ceFfe8283F07EB1447E39a;
    address constant internal CHALLENGER = 0x6F8C5bA3F59ea3E76300E3BEcDC231D656017824;
    address constant internal SAFE = 0x9855054731540A48b28990B63DcF4f33d8AE46A1;

    function _postCheck() internal override view {
        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_CONTRACT);
        require(
            proxyAdmin.getProxyImplementation(L2_OUTPUT_ORACLE_PROXY).codehash == NEW_IMPLEMENTATION.codehash,
            "UpgradeL2OutputOracle: L2OutpuOracle not upgraded"
        );

        L2OutputOracle l2OutputOracle = L2OutputOracle(L2_OUTPUT_ORACLE_PROXY);
        require(l2OutputOracle.CHALLENGER() == CHALLENGER, "UpgradeL2OutputOracle: Challenger was not set properly");
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        L2OutputOracle l2OutputOracle = L2OutputOracle(NEW_IMPLEMENTATION);
        require(l2OutputOracle.CHALLENGER() == CHALLENGER, "UpgradeL2OutputOracle: Challenger is incorrect");

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: PROXY_ADMIN_CONTRACT,
            allowFailure: false,
            callData: abi.encodeCall(
                ProxyAdmin.upgrade,
                (payable(L2_OUTPUT_ORACLE_PROXY), NEW_IMPLEMENTATION)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return SAFE;
    }
}