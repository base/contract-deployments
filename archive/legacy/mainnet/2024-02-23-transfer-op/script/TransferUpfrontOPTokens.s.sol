// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO: this script will be called after the upfront grant tokens have vested
contract TransferOPTokens is NestedMultisigBuilder {
    address internal NESTED_SAFE = vm.envAddress("NESTED_SAFE");
    IERC20 public OP_TOKEN = IERC20(vm.envAddress("OP_TOKEN"));
    address public BENEFICIARY = vm.envAddress("BENEFICIARY");
    uint256 public UPFRONT_GRANT_TOKENS = vm.envUint("UPFRONT_GRANT_TOKENS");

    function _postCheck() internal override view {
        require(
            OP_TOKEN.balanceOf(BENEFICIARY) >= UPFRONT_GRANT_TOKENS,
            "TransferAndDelegateOPTokens: tokens not transferred to beneficiary"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        // There should be UPFRONT_GRANT_TOKENS left in the NESTED_SAFE. However,
        // there could be more since anyone could send OP to the safe, so check if the
        // amount is greater than or equal
        require(
            OP_TOKEN.balanceOf(NESTED_SAFE) >= UPFRONT_GRANT_TOKENS,
            "TransferOPTokens: unexpected token amount in nested safe"
        );

        // Transfer upfront grant tokens when they vest
        calls[0] = IMulticall3.Call3({
            target: address(OP_TOKEN),
            allowFailure: false,
            callData: abi.encodeCall(
                IERC20.transfer,
                (BENEFICIARY, UPFRONT_GRANT_TOKENS)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return NESTED_SAFE;
    }
}