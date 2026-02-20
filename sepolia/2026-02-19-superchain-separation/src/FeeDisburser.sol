// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IL2StandardBridge} from "@eth-optimism-bedrock/interfaces/L2/IL2StandardBridge.sol";
import {IFeeVault, Types} from "@eth-optimism-bedrock/interfaces/L2/IFeeVault.sol";
import {Predeploys} from "@eth-optimism-bedrock/src/libraries/Predeploys.sol";

/// @title FeeDisburser
/// @notice Withdraws funds from system FeeVault contracts and bridges to L1.
contract FeeDisburser {
    ////////////////////////////////////////////////////////////////
    ///                     Constants
    ////////////////////////////////////////////////////////////////

    /// @notice The minimum gas limit for the FeeDisburser withdrawal transaction to L1.
    uint32 public constant WITHDRAWAL_MIN_GAS = 35_000;

    ////////////////////////////////////////////////////////////////
    ///                     Immutables
    ////////////////////////////////////////////////////////////////

    /// @notice The address of the L1 wallet that will receive the OP chain runner's share of fees.
    address public immutable L1_WALLET;

    /// @notice The minimum amount of time in seconds that must pass between fee disbursals.
    uint256 public immutable FEE_DISBURSEMENT_INTERVAL;

    ////////////////////////////////////////////////////////////////
    ///                     Storage
    ////////////////////////////////////////////////////////////////

    /// @notice The timestamp of the last disbursal.
    uint256 public lastDisbursementTime;

    /// @notice Tracks aggregate net fee revenue which is the sum of sequencer and base fees.
    ///
    /// @dev Explicitly tracking Net Revenue is required to separate L1FeeVault initiated
    ///      withdrawals from Net Revenue calculations.
    /// @dev This variable is deprecated.
    uint256 public netFeeRevenue;

    ////////////////////////////////////////////////////////////////
    ///                       Events
    ////////////////////////////////////////////////////////////////

    /// @notice Emitted when fees are disbursed.
    ///
    /// @param disbursementTime The time of the disbursement.
    /// @param totalFeesDisbursed The total amount of fees disbursed.
    event FeesDisbursed(uint256 disbursementTime, uint256 totalFeesDisbursed);

    /// @notice Emitted when fees are received from FeeVaults.
    ///
    /// @param sender The FeeVault that sent the fees.
    /// @param amount The amount of fees received.
    event FeesReceived(address indexed sender, uint256 amount);

    /// @notice Emitted when no fees are collected from FeeVaults at time of disbursement.
    event NoFeesCollected();

    ////////////////////////////////////////////////////////////////
    ///                        Errors
    ////////////////////////////////////////////////////////////////

    /// @notice Thrown when the L1 wallet address is the zero address.
    error ZeroAddress();

    /// @notice Thrown when the fee disbursement interval is less than 24 hours.
    error IntervalTooLow();

    /// @notice Thrown when disburseFees is called before the disbursement interval has passed.
    error IntervalNotReached();

    /// @notice Thrown when a FeeVault's withdrawal network is not set to L2.
    error FeeVaultMustWithdrawToL2();

    /// @notice Thrown when a FeeVault's recipient is not set to the FeeDisburser contract.
    error FeeVaultMustWithdrawToFeeDisburser();

    ////////////////////////////////////////////////////////////////
    ///                     Constructor
    ////////////////////////////////////////////////////////////////

    /// @notice Constructor for the FeeDisburser contract which validates and sets immutable variables.
    ///
    /// @param l1Wallet                The L1 address which receives the remainder of the revenue.
    /// @param feeDisbursementInterval The minimum amount of time in seconds that must pass between fee disbursals.
    constructor(address l1Wallet, uint256 feeDisbursementInterval) {
        require(l1Wallet != address(0), ZeroAddress());
        require(feeDisbursementInterval >= 24 hours, IntervalTooLow());

        L1_WALLET = l1Wallet;
        FEE_DISBURSEMENT_INTERVAL = feeDisbursementInterval;
    }

    ////////////////////////////////////////////////////////////////
    ///                     External Functions
    ////////////////////////////////////////////////////////////////

    /// @notice Withdraws funds from FeeVaults and bridges to L1.
    function disburseFees() external virtual {
        require(block.timestamp >= lastDisbursementTime + FEE_DISBURSEMENT_INTERVAL, IntervalNotReached());

        // Sequencer and base FeeVaults will withdraw fees to the FeeDisburser contract mutating netFeeRevenue
        _feeVaultWithdrawal(payable(Predeploys.SEQUENCER_FEE_WALLET));
        _feeVaultWithdrawal(payable(Predeploys.BASE_FEE_VAULT));
        _feeVaultWithdrawal(payable(Predeploys.L1_FEE_VAULT));

        // Gross revenue is the sum of all fees
        uint256 feeBalance = address(this).balance;

        // Stop execution if no fees were collected
        if (feeBalance == 0) {
            emit NoFeesCollected();
            return;
        }

        lastDisbursementTime = block.timestamp;

        // Send remaining funds to L1 wallet on L1
        IL2StandardBridge(payable(Predeploys.L2_STANDARD_BRIDGE)).bridgeETHTo{value: address(this).balance}(
            L1_WALLET, WITHDRAWAL_MIN_GAS, bytes("")
        );

        emit FeesDisbursed(lastDisbursementTime, feeBalance);
    }

    /// @notice Receives ETH fees withdrawn from L2 FeeVaults.
    receive() external payable virtual {
        emit FeesReceived(msg.sender, msg.value);
    }

    ////////////////////////////////////////////////////////////////
    ///                     Private Functions
    ////////////////////////////////////////////////////////////////

    /// @notice Withdraws fees from a FeeVault.
    ///
    /// @dev Withdrawal will only occur if the given FeeVault's balance is greater than or equal to the minimum
    ///      withdrawal amount.
    ///
    /// @param feeVault The address of the FeeVault to withdraw from.
    function _feeVaultWithdrawal(address payable feeVault) private {
        require(IFeeVault(feeVault).WITHDRAWAL_NETWORK() == Types.WithdrawalNetwork.L2, FeeVaultMustWithdrawToL2());
        require(IFeeVault(feeVault).RECIPIENT() == address(this), FeeVaultMustWithdrawToFeeDisburser());

        if (feeVault.balance >= IFeeVault(feeVault).MIN_WITHDRAWAL_AMOUNT()) {
            IFeeVault(feeVault).withdraw();
        }
    }
}
