// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";

import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

contract FundScript is MultisigScript {
    address internal immutable SAFE;

    uint256 internal immutable SAFE_BALANCE_BEFORE;
    uint256 internal immutable TOTAL_FUNDS;

    address[] internal RECIPIENTS;
    uint256[] internal FUNDS;
    uint256[] internal RECIPIENT_BALANCES_BEFORE;

    constructor() {
        Chain memory chain = getChain(block.chainid);
        console.log("Deploying on chain: %s", chain.name);

        SAFE = vm.envAddress("SAFE");

        string memory funding = vm.readFile("./funding.json");
        RECIPIENTS = vm.parseJsonAddressArray(funding, ".recipients");
        FUNDS = vm.parseJsonUintArray(funding, ".funds");

        uint256 totalFunds = 0;
        RECIPIENT_BALANCES_BEFORE = new uint256[](RECIPIENTS.length);
        for (uint256 i; i < RECIPIENTS.length; i++) {
            RECIPIENT_BALANCES_BEFORE[i] = RECIPIENTS[i].balance;
            totalFunds += FUNDS[i];
        }

        SAFE_BALANCE_BEFORE = SAFE.balance;
        TOTAL_FUNDS = totalFunds;
    }

    function setUp() public view {
        _precheck();
    }

    function _precheck() internal view {
        require(RECIPIENTS.length == FUNDS.length, "RECIPIENTS and FUNDS not same length");
        require(RECIPIENTS.length > 0, "RECIPIENTS and FUNDS empty");
        require(SAFE.balance >= TOTAL_FUNDS, "SAFE not enough balance");
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3Value[] memory) {
        IMulticall3.Call3Value[] memory calls = new IMulticall3.Call3Value[](RECIPIENTS.length);
        for (uint256 i; i < RECIPIENTS.length; i++) {
            calls[i] =
                IMulticall3.Call3Value({target: RECIPIENTS[i], allowFailure: false, callData: "", value: FUNDS[i]});
        }

        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        for (uint256 i; i < RECIPIENTS.length; i++) {
            vm.assertEq(
                RECIPIENTS[i].balance, RECIPIENT_BALANCES_BEFORE[i] + FUNDS[i], "Recipient balance is not correct"
            );
        }

        vm.assertEq(SAFE.balance, SAFE_BALANCE_BEFORE - TOTAL_FUNDS, "Owner safe balance is not correct");
    }

    function _ownerSafe() internal view override returns (address) {
        return SAFE;
    }
}
