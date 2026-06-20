// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TestNestedL2Safe is NestedMultisigBuilder {
    address constant internal OP_TOKEN_ADDR = 0x4200000000000000000000000000000000000042;
    // OP Token Address
    IERC20 constant internal OP_TOKEN = IERC20(OP_TOKEN_ADDR);
    // 2-of-2 (CB + OP) fee vault
    address constant internal NESTED_L2_SAFE = 0x0a7361e734cf3f0394B0FC4a45C74E7a4Ec70940;
    // Address to send OP test txn to
    address constant internal SEND_OP_TO = 0x05301B36f071CEfD01e564EC5eCCe6864d12b0B0;

    function _postCheck() internal override view {
        uint256 opBalance =  OP_TOKEN.balanceOf(NESTED_L2_SAFE);

        require(
            opBalance == 0,
            "TestNestedL2Safe: script failed to transfer total balance"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        uint256 opBalance = OP_TOKEN.balanceOf(NESTED_L2_SAFE);

        require(
            opBalance > 0 && opBalance <= 10 ether,
            "TestNestedL2Safe: transfer a test amount of OP to the nested l2 safe"
        );

        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: OP_TOKEN_ADDR,
            allowFailure: false,
            callData: abi.encodeCall(
                IERC20.transfer,
                (SEND_OP_TO, opBalance)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override pure returns (address) {
        return NESTED_L2_SAFE;
    }
}