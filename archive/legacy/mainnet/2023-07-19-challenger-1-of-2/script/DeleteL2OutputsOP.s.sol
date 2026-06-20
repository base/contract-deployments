// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@eth-optimism-bedrock/contracts/L1/L2OutputOracle.sol";
import "@base-contracts/src/Challenger1of2.sol";
import "@base-contracts/script/universal/MultisigBuilder.sol";

contract DeleteL2OutputsOP is MultisigBuilder {
    address constant internal L2_OUTPUT_ORACLE_PROXY = 0x56315b90c40730925ec5485cf004d835058518A0;
    address constant internal CHALLENGER = 0x6F8C5bA3F59ea3E76300E3BEcDC231D656017824;
    address constant internal SAFE = 0x9BA6e03D8B90dE867373Db8cF1A58d2F7F006b3A;

    function _postCheck() internal override view {
        // perform post execution checks
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        L2OutputOracle l2OutputOracle = L2OutputOracle(L2_OUTPUT_ORACLE_PROXY);
        bytes memory deleteL2OutputData = abi.encodeCall(
            L2OutputOracle.deleteL2Outputs, (1359)
        );

        calls[0] = IMulticall3.Call3({
            target: CHALLENGER,
            allowFailure: false,
            callData: abi.encodeCall(
                Challenger1of2.execute, (deleteL2OutputData)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return SAFE;
    }
}