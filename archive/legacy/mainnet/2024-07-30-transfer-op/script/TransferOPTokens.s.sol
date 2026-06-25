// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferOPTokens is NestedMultisigBuilder {
    address internal NESTED_SAFE = vm.envAddress("NESTED_SAFE");
    IERC20 public OP_TOKEN = IERC20(vm.envAddress("OP_TOKEN"));
    address internal SMART_ESCROW = vm.envAddress("SMART_ESCROW_CONTRACT");
    uint256 internal TOKENS_TO_TRANSFER = vm.envUint("TOKENS_TO_TRANSFER");

    function _postCheck() internal override view {
        require(
            OP_TOKEN.balanceOf(SMART_ESCROW) >= TOKENS_TO_TRANSFER,
            "TransferOPTokens: tokens not transferred to SmartEscrow contract"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        // There should be TOKENS_TO_TRANSFER tokens in the NESTED_SAFE. However,
        // there could be more since anyone could send OP to the safe, so check if the
        // amount is greater than or equal
        require(
            OP_TOKEN.balanceOf(NESTED_SAFE) >= TOKENS_TO_TRANSFER,
            "TransferOPTokens: unexpected token amount in nested safe"
        );

        // Transfer token to SmartEscrow contract
        calls[0] = IMulticall3.Call3({
            target: address(OP_TOKEN),
            allowFailure: false,
            callData: abi.encodeCall(
                IERC20.transfer,
                (SMART_ESCROW, TOKENS_TO_TRANSFER)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return NESTED_SAFE;
    }
}