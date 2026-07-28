// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@agora/structs/RulesV3.sol";
import "@agora/structs/AllowanceType.sol";
import "@agora/alligator/AlligatorOP_V5.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferAndDelegateOPTokens is NestedMultisigBuilder {
    IERC20 internal OP_TOKEN = IERC20(vm.envAddress("OP_TOKEN"));

    address internal NESTED_SAFE = vm.envAddress("NESTED_SAFE");
    address internal SMART_ESCROW = vm.envAddress("SMART_ESCROW_CONTRACT");
    address internal ALLIGATOR_PROXY = vm.envAddress("ALLIGATOR_PROXY"); // Agora address which will allow for subdelegation
    address internal BENEFICIARY = vm.envAddress("BENEFICIARY");
    uint256 internal UPFRONT_GRANT_TOKENS = vm.envUint("UPFRONT_GRANT_TOKENS");
    uint256 internal TOKENS_TO_TRANSFER = vm.envUint("TOKENS_TO_TRANSFER");

    function _postCheck() internal override view {
        require(
            OP_TOKEN.balanceOf(SMART_ESCROW) >= TOKENS_TO_TRANSFER,
            "TransferAndDelegateOPTokens: tokens not transferred to smart escrow"
        );
        require(
            OP_TOKEN.balanceOf(NESTED_SAFE) >= UPFRONT_GRANT_TOKENS,
            "TransferAndDelegateOPTokens: number of remaining tokens in nested safe is incorrect"
        );
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](3);

        // Double check that there are enough tokens to transfer
        uint256 remainingTokens = OP_TOKEN.balanceOf(NESTED_SAFE) - TOKENS_TO_TRANSFER;
        require(
            remainingTokens >= UPFRONT_GRANT_TOKENS,
            "TransferAndDelegateOPTokens: not enough tokens to transfer"
        );

        // Transfer collaboration grant tokens which are in the nested safe to smart escrow
        // Tokens are sent to the contract 1 year before they vest, so this will be some subset of the
        // total collaboration grant tokens
        calls[0] = IMulticall3.Call3({
            target: address(OP_TOKEN),
            allowFailure: false,
            callData: abi.encodeCall(
                IERC20.transfer,
                (SMART_ESCROW, TOKENS_TO_TRANSFER)
            )
        });
        // Delegate governance tokens for initial grant to Agora's Alligator proxy,
        // which will allow for subdelegations
        calls[1] = IMulticall3.Call3({
            target: address(OP_TOKEN),
            allowFailure: false,
            callData: abi.encodeCall(
                ERC20Votes.delegate,
                (AlligatorOPV5(ALLIGATOR_PROXY).proxyAddress(NESTED_SAFE))
            )
        });

        // Setup subdelegation rules
        // The intended functionality here is that the wallet we delegate to should be able to redelegate,
        // but the wallet(s) it redelegates to should not be able to redelegate further.
        // In addition, we want to delegate an absolute amount, since only the Upfront Grant tokens are eligible
        // to be voted with before the 1 year vesting. There shouldn't be any additional OP tokens sent to this wallet,
        // but if there are, we should not delegate them.
        // The rest of the rules are set to the defaults and are not relevant for our use case.
        SubdelegationRules memory subdelegationRules = SubdelegationRules({
            maxRedelegations: 1,
            blocksBeforeVoteCloses: 0,
            notValidBefore: 0,
            notValidAfter: 0,
            customRule: address(0),
            allowanceType: AllowanceType.Absolute,
            allowance: UPFRONT_GRANT_TOKENS
        });

        // Delegate the tokens to the Coinbase owned address
        calls[2] = IMulticall3.Call3({
            target: ALLIGATOR_PROXY,
            allowFailure: false,
            callData: abi.encodeCall(
                AlligatorOPV5.subdelegate,
                (BENEFICIARY, subdelegationRules)
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return NESTED_SAFE;
    }
}
