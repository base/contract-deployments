// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm, VmSafe} from "forge-std/Vm.sol";

import {IOptimismPortal2} from "interfaces/L1/IOptimismPortal2.sol";
import {IFeeVault} from "interfaces/L2/IFeeVault.sol";
import {IProxyAdmin} from "interfaces/universal/IProxyAdmin.sol";
import {ISemver} from "interfaces/universal/ISemver.sol";

import {Predeploys} from "src/libraries/Predeploys.sol";
import {Types} from "src/libraries/Types.sol";
import {AddressAliasHelper} from "src/vendor/AddressAliasHelper.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";

/// @notice Upgrades the L2ToL1MessagePasser, L1Block and fee vault predeploys through deposit transactions sent by
///         the ProxyAdmin owner, whose L2 alias owns the L2 ProxyAdmin.
/// @dev Each upgrade is its own deposit to the L2 ProxyAdmin so that it sees the aliased owner as the caller. Fee
///      vaults 1.6.0 read their config from storage instead of immutables, so they are upgraded with `initialize`.
///      The L1 simulation cannot run the deposits, so the post-check replays them on an L2 fork.
contract UpgradeL2Predeploys is MultisigScript {
    /// @dev L2 gas bought for each upgrade deposit. `upgradeAndCall` with `initialize` uses about 100k.
    uint64 internal constant L2_GAS_LIMIT = 200_000;

    string internal constant L2_TO_L1_MESSAGE_PASSER_VERSION = "1.2.0";
    string internal constant L1_BLOCK_VERSION = "1.8.0";
    string internal constant FEE_VAULT_VERSION = "1.6.0";

    // Task config from .env.
    address internal immutable ownerSafe;
    address internal immutable optimismPortal;
    string internal l2RpcUrl;
    address internal immutable l2ToL1MessagePasserImpl;
    address internal immutable l1BlockImpl;
    address internal immutable sequencerFeeVaultImpl;
    address internal immutable baseFeeVaultImpl;
    address internal immutable l1FeeVaultImpl;
    address internal immutable feeVaultRecipient;
    uint256 internal immutable feeVaultMinWithdrawalAmount;
    Types.WithdrawalNetwork internal immutable feeVaultWithdrawalNetwork;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        l2RpcUrl = vm.envString("L2_RPC_URL");
        l2ToL1MessagePasserImpl = vm.envAddress("L2_TO_L1_MESSAGE_PASSER_IMPL");
        l1BlockImpl = vm.envAddress("L1_BLOCK_IMPL");
        sequencerFeeVaultImpl = vm.envAddress("SEQUENCER_FEE_VAULT_IMPL");
        baseFeeVaultImpl = vm.envAddress("BASE_FEE_VAULT_IMPL");
        l1FeeVaultImpl = vm.envAddress("L1_FEE_VAULT_IMPL");
        feeVaultRecipient = vm.envAddress("FEE_VAULT_RECIPIENT");
        feeVaultMinWithdrawalAmount = vm.envUint("FEE_VAULT_MIN_WITHDRAWAL_AMOUNT");
        feeVaultWithdrawalNetwork = Types.WithdrawalNetwork(vm.envUint("FEE_VAULT_WITHDRAWAL_NETWORK"));
    }

    function setUp() public view {
        require(!IOptimismPortal2(payable(optimismPortal)).paused(), "optimism portal paused");
        require(feeVaultRecipient != address(0), "fee vault recipient not set");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        bytes[] memory l2Calls = _l2Calls();
        Call[] memory calls = new Call[](l2Calls.length);
        for (uint256 i; i < l2Calls.length; i++) {
            calls[i] = Call({
                operation: Enum.Operation.Call,
                target: optimismPortal,
                data: abi.encodeCall(
                    IOptimismPortal2.depositTransaction, (Predeploys.PROXY_ADMIN, 0, L2_GAS_LIMIT, false, l2Calls[i])
                ),
                value: 0
            });
        }
        return calls;
    }

    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory) internal override {
        _assertDeposits(accesses);
        _assertL2Upgrade();
    }

    /// @dev Checks that the Safe called the portal once per upgrade, without reverting.
    function _assertDeposits(Vm.AccountAccess[] memory accesses) internal view {
        bytes4 depositSelector = IOptimismPortal2.depositTransaction.selector;
        uint256 deposits;
        for (uint256 i; i < accesses.length; i++) {
            Vm.AccountAccess memory access = accesses[i];
            if (access.kind != VmSafe.AccountAccessKind.Call || access.account != optimismPortal) continue;
            if (access.data.length < 4 || bytes4(access.data) != depositSelector) continue;
            require(access.accessor == ownerSafe, "deposit not sent by the proxy admin owner");
            require(!access.reverted, "deposit reverted");
            deposits++;
        }
        require(deposits == _l2Calls().length, "unexpected deposit count");
    }

    /// @dev Replays each deposit on an L2 fork as the aliased owner and checks the upgraded predeploys.
    function _assertL2Upgrade() internal {
        uint256 l1Fork = vm.activeFork();
        vm.createSelectFork(l2RpcUrl);

        address aliasedOwner = AddressAliasHelper.applyL1ToL2Alias(ownerSafe);
        require(IProxyAdmin(Predeploys.PROXY_ADMIN).owner() == aliasedOwner, "l2 proxy admin owner mismatch");

        bytes[] memory l2Calls = _l2Calls();
        for (uint256 i; i < l2Calls.length; i++) {
            vm.prank(aliasedOwner);
            (bool success,) = Predeploys.PROXY_ADMIN.call{gas: L2_GAS_LIMIT}(l2Calls[i]);
            require(success, "l2 upgrade reverted");
        }

        _assertPredeploy(Predeploys.L2_TO_L1_MESSAGE_PASSER, l2ToL1MessagePasserImpl, L2_TO_L1_MESSAGE_PASSER_VERSION);
        _assertPredeploy(Predeploys.L1_BLOCK_ATTRIBUTES, l1BlockImpl, L1_BLOCK_VERSION);
        _assertFeeVault(Predeploys.SEQUENCER_FEE_WALLET, sequencerFeeVaultImpl);
        _assertFeeVault(Predeploys.BASE_FEE_VAULT, baseFeeVaultImpl);
        _assertFeeVault(Predeploys.L1_FEE_VAULT, l1FeeVaultImpl);

        vm.selectFork(l1Fork);
    }

    function _assertFeeVault(address proxy, address impl) internal view {
        _assertPredeploy(proxy, impl, FEE_VAULT_VERSION);

        IFeeVault vault = IFeeVault(payable(proxy));
        require(vault.recipient() == feeVaultRecipient, "fee vault recipient mismatch");
        require(vault.minWithdrawalAmount() == feeVaultMinWithdrawalAmount, "fee vault min withdrawal mismatch");
        require(vault.withdrawalNetwork() == feeVaultWithdrawalNetwork, "fee vault withdrawal network mismatch");
    }

    function _assertPredeploy(address proxy, address impl, string memory version) internal view {
        require(
            IProxyAdmin(Predeploys.PROXY_ADMIN).getProxyImplementation(proxy) == impl,
            "predeploy implementation mismatch"
        );
        require(_eq(ISemver(proxy).version(), version), "predeploy version mismatch");
    }

    /// @dev Calls to the L2 ProxyAdmin, one deposit each.
    function _l2Calls() internal view returns (bytes[] memory calls) {
        bytes memory initializeFeeVault = abi.encodeCall(
            IFeeVault.initialize, (feeVaultRecipient, feeVaultMinWithdrawalAmount, feeVaultWithdrawalNetwork)
        );

        calls = new bytes[](5);
        calls[0] =
            abi.encodeCall(IProxyAdmin.upgrade, (payable(Predeploys.L2_TO_L1_MESSAGE_PASSER), l2ToL1MessagePasserImpl));
        calls[1] = abi.encodeCall(IProxyAdmin.upgrade, (payable(Predeploys.L1_BLOCK_ATTRIBUTES), l1BlockImpl));
        calls[2] = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (payable(Predeploys.SEQUENCER_FEE_WALLET), sequencerFeeVaultImpl, initializeFeeVault)
        );
        calls[3] = abi.encodeCall(
            IProxyAdmin.upgradeAndCall, (payable(Predeploys.BASE_FEE_VAULT), baseFeeVaultImpl, initializeFeeVault)
        );
        calls[4] = abi.encodeCall(
            IProxyAdmin.upgradeAndCall, (payable(Predeploys.L1_FEE_VAULT), l1FeeVaultImpl, initializeFeeVault)
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
