// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "forge-std/console.sol";
import {LegacyMigrator} from "./LegacyMigrator.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

import {IOptimismPortal2} from "interfaces/L1/IOptimismPortal2.sol";
import {IFeeVault, Types} from "interfaces/L2/IFeeVault.sol";
import {IProxyAdmin as IL2ProxyAdmin} from "interfaces/universal/IProxyAdmin.sol";
import {ISemver} from "interfaces/universal/ISemver.sol";
import {Predeploys} from "@base-contracts/src/libraries/Predeploys.sol";
import {AddressAliasHelper} from "@base-contracts/src/vendor/AddressAliasHelper.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

import {IAggregateVerifierV020} from "./IAggregateVerifierV020.sol";

interface IMainnetSafe {
    function getThreshold() external view returns (uint256);
    function getOwners() external view returns (address[] memory);
}

interface IProxyAdmin {
    function owner() external view returns (address);
}

interface IDisputeGameFactoryAdmin {
    function gameArgs(GameType gameType) external view returns (bytes memory);
    function gameCount() external view returns (uint256);
    function gameImpls(GameType gameType) external view returns (address);
    function owner() external view returns (address);
    function setImplementation(GameType gameType, address impl) external;
}

interface IProtocolVersions {
    function MIN_NOTICE() external view returns (uint64);
    function getSchedule() external view returns (uint64[] memory);
    function minimumProtocolVersion() external view returns (uint256);
    function registerUpgrade(uint64 timestamp, uint256 minProtocolVersion) external returns (uint256);
}

/// @notice Registers Denim and upgrades thirteen L2 predeploys in one ProxyAdmin-owner transaction.

contract ExecuteDenimUpgradeWithAllL2Predeploys is MultisigScript {
    // Each deposit must call the L2 ProxyAdmin directly so it sees the aliased owner, not an L2 multicall.
    // The L1 simulation cannot execute deposits, so the post-check replays them on an L2 fork.
    uint64 internal constant L2_GAS_LIMIT = 300_000;
    string internal constant L2_TO_L1_MESSAGE_PASSER_VERSION = "1.2.0";
    string internal constant L1_BLOCK_VERSION = "1.8.0";
    string internal constant FEE_VAULT_VERSION = "1.6.0";

    address internal immutable optimismPortal;
    uint256 internal immutable l2Fork;
    address internal immutable l2ToL1MessagePasserImpl;
    address internal immutable l1BlockImpl;
    address internal immutable sequencerFeeVaultImpl;
    address internal immutable baseFeeVaultImpl;
    address internal immutable l1FeeVaultImpl;
    address internal immutable feeVaultRecipient;
    uint256 internal immutable feeVaultMinWithdrawalAmount;
    Types.WithdrawalNetwork internal immutable feeVaultWithdrawalNetwork;
    uint256 internal constant DENIM_UPGRADE_ID = 13;

    string internal constant OLD_VERSION = "0.2.0";
    string internal constant NEW_VERSION = "0.3.0";

    address internal immutable ownerSafe;
    address internal immutable baseSafe = vm.envAddress("CB_MULTISIG");
    address internal immutable councilSafe = vm.envAddress("BASE_SECURITY_COUNCIL");
    address internal immutable proxyAdmin;
    address internal immutable disputeGameFactory;
    GameType internal immutable gameType;
    address internal immutable oldAggregateVerifier;
    address internal immutable newAggregateVerifier;
    bytes32 internal immutable teeImageHash;
    bytes32 internal immutable zkRangeHash;
    bytes32 internal immutable zkAggregateHash;
    uint256 internal immutable fastBlockInterval;
    uint256 internal immutable fastIntermediateBlockInterval;
    uint64 internal immutable denimActivationTimestamp;
    uint256 internal immutable currentMinimumProtocolVersion;
    uint256 internal immutable newMinimumProtocolVersion;

    // Live state captured at construction and re-asserted after execution.
    address internal immutable protocolVersions;
    uint256 internal immutable gameCountBefore;
    bytes32 internal immutable scheduleHashBefore;

    constructor() {
        optimismPortal = vm.envAddress("OPTIMISM_PORTAL");
        l2Fork = vm.createFork(vm.envString("L2_RPC_URL"));
        l2ToL1MessagePasserImpl = vm.envAddress("L2_TO_L1_MESSAGE_PASSER_IMPL");
        l1BlockImpl = vm.envAddress("L1_BLOCK_IMPL");
        sequencerFeeVaultImpl = vm.envAddress("SEQUENCER_FEE_VAULT_IMPL");
        baseFeeVaultImpl = vm.envAddress("BASE_FEE_VAULT_IMPL");
        l1FeeVaultImpl = vm.envAddress("L1_FEE_VAULT_IMPL");
        require(
            l2ToL1MessagePasserImpl != address(0) && l1BlockImpl != address(0) && sequencerFeeVaultImpl != address(0)
                && baseFeeVaultImpl != address(0) && l1FeeVaultImpl != address(0),
            "L2 implementation address missing"
        );
        feeVaultRecipient = vm.envAddress("FEE_VAULT_RECIPIENT");
        feeVaultMinWithdrawalAmount = vm.envUint("FEE_VAULT_MIN_WITHDRAWAL_AMOUNT");
        feeVaultWithdrawalNetwork = Types.WithdrawalNetwork(vm.envUint("FEE_VAULT_WITHDRAWAL_NETWORK"));
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        disputeGameFactory = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        gameType = GameType.wrap(uint32(vm.envUint("GAME_TYPE")));
        oldAggregateVerifier = vm.envAddress("OLD_AGGREGATE_VERIFIER");
        newAggregateVerifier = vm.envAddress("NEW_AGGREGATE_VERIFIER");
        teeImageHash = vm.envBytes32("AGGREGATE_VERIFIER_TEE_IMAGE_HASH");
        zkRangeHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_RANGE_HASH");
        zkAggregateHash = vm.envBytes32("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH");
        fastBlockInterval = vm.envUint("FAST_BLOCK_INTERVAL");
        fastIntermediateBlockInterval = vm.envUint("FAST_INTERMEDIATE_BLOCK_INTERVAL");
        denimActivationTimestamp = uint64(vm.envUint("PROTOCOL_VERSIONS_DENIM_ACTIVATION_TIMESTAMP"));
        currentMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_CURRENT_MINIMUM_PROTOCOL_VERSION");
        newMinimumProtocolVersion = vm.envUint("PROTOCOL_VERSIONS_MINIMUM_PROTOCOL_VERSION");

        address registry = IAggregateVerifierV020(oldAggregateVerifier).PROTOCOL_VERSIONS();
        protocolVersions = registry;
        gameCountBefore = IDisputeGameFactoryAdmin(disputeGameFactory).gameCount();
        scheduleHashBefore = keccak256(abi.encode(IProtocolVersions(registry).getSchedule()));
    }

    function setUp() public {
        require(block.chainid == 1, "wrong L1 chain");
        uint256 l1Fork = vm.activeFork();
        vm.selectFork(l2Fork);
        require(block.chainid == 8453, "wrong L2 chain");
        _assertL2Before();
        vm.selectFork(l1Fork);
        require(
            teeImageHash != bytes32(0) && zkRangeHash != bytes32(0) && zkAggregateHash != bytes32(0),
            "prover hashes missing"
        );
        require(!IOptimismPortal2(payable(optimismPortal)).paused(), "optimism portal paused");
        require(_eq(ISemver(optimismPortal).version(), "6.0.1"), "portal version changed");
        require(
            uint256(L2_GAS_LIMIT) * 13
                < IOptimismPortal2(payable(optimismPortal)).systemConfig().resourceConfig().maxResourceLimit,
            "deposits exhaust portal resource limit"
        );
        require(feeVaultRecipient != address(0), "fee vault recipient not set");
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        // Both calls are authorized against the same Safe: the factory owner and the ProxyAdmin owner.
        require(dgf.owner() == ownerSafe, "dgf owner mismatch");
        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");
        _assertSafe(ownerSafe, 2, 2);
        _assertSafe(baseSafe, 3, 6);
        _assertSafe(councilSafe, 8, 11);
        address[] memory owners = IMainnetSafe(ownerSafe).getOwners();
        require(
            (owners[0] == baseSafe && owners[1] == councilSafe) || (owners[1] == baseSafe && owners[0] == councilSafe),
            "owner Safe members changed"
        );
        require(IAggregateVerifierV020(oldAggregateVerifier).BLOCK_INTERVAL() == 600, "slow interval changed");
        require(
            IAggregateVerifierV020(oldAggregateVerifier).INTERMEDIATE_BLOCK_INTERVAL() == 30,
            "slow intermediate interval changed"
        );

        require(dgf.gameImpls(gameType) == oldAggregateVerifier, "unexpected current aggregate verifier");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args not empty");
        require(_eq(IAggregateVerifierV020(oldAggregateVerifier).version(), OLD_VERSION), "unexpected current version");
        require(newAggregateVerifier.code.length != 0, "new aggregate verifier not deployed");
        require(newAggregateVerifier != oldAggregateVerifier, "new aggregate verifier is the current one");
        require(_eq(AggregateVerifier(newAggregateVerifier).version(), NEW_VERSION), "new version mismatch");
        _assertNewVerifier();

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == DENIM_UPGRADE_ID, "unexpected upgrade count");
        require(schedule[7] == 0 && schedule[12] == 1790791200, "legacy schedule changed");
        require(registry.MIN_NOTICE() == 3600, "minimum notice changed");
        require(denimActivationTimestamp > schedule[schedule.length - 1], "denim must activate after cobalt");
        require(
            denimActivationTimestamp >= uint64(block.timestamp) + registry.MIN_NOTICE(),
            "denim activation inside MIN_NOTICE"
        );
        require(
            registry.minimumProtocolVersion() == currentMinimumProtocolVersion,
            "current minimum protocol version mismatch"
        );
        require(newMinimumProtocolVersion > currentMinimumProtocolVersion, "minimum protocol version not increased");
        require(newMinimumProtocolVersion <= type(uint128).max, "minimum protocol version too large");
    }

    function _assertSafe(address safe, uint256 threshold, uint256 owners) internal view {
        require(IMainnetSafe(safe).getThreshold() == threshold, "Safe threshold changed");
        require(IMainnetSafe(safe).getOwners().length == owners, "Safe owner count changed");
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        bytes[] memory l2Calls = _l2Calls();
        Call[] memory calls = new Call[](2 + l2Calls.length);

        // Swap the verifier first so it is live before the schedule it reads gains the Denim entry.
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: disputeGameFactory,
            data: abi.encodeCall(IDisputeGameFactoryAdmin.setImplementation, (gameType, newAggregateVerifier)),
            value: 0
        });

        calls[1] = Call({
            operation: Enum.Operation.Call,
            target: protocolVersions,
            data: abi.encodeCall(
                IProtocolVersions.registerUpgrade, (denimActivationTimestamp, newMinimumProtocolVersion)
            ),
            value: 0
        });

        for (uint256 i; i < l2Calls.length; i++) {
            calls[2 + i] = Call({
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
        _assertDenimUpgrade();
        _assertDeposits(accesses);
        _assertL2Upgrade();
    }

    function _assertDenimUpgrade() internal view {
        IDisputeGameFactoryAdmin dgf = IDisputeGameFactoryAdmin(disputeGameFactory);
        IProtocolVersions registry = IProtocolVersions(protocolVersions);

        require(dgf.gameImpls(gameType) == newAggregateVerifier, "aggregate verifier not registered");
        require(dgf.gameArgs(gameType).length == 0, "aggregate game args changed");
        require(dgf.gameCount() == gameCountBefore, "game count changed");

        uint64[] memory schedule = registry.getSchedule();
        require(schedule.length == DENIM_UPGRADE_ID + 1, "denim not registered");
        require(schedule[DENIM_UPGRADE_ID] == denimActivationTimestamp, "denim activation mismatch");
        uint64[] memory previous = new uint64[](DENIM_UPGRADE_ID);
        for (uint256 i = 0; i < DENIM_UPGRADE_ID; i++) {
            previous[i] = schedule[i];
        }
        require(keccak256(abi.encode(previous)) == scheduleHashBefore, "previous upgrades changed");
        require(registry.minimumProtocolVersion() == newMinimumProtocolVersion, "minimum protocol version not updated");

        // The new verifier must switch to the fast intervals exactly at the first Denim block.
        _assertNewVerifier();
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);
        uint256 firstFastBlock = av.L2_GENESIS_BLOCK_NUMBER()
            + _divUp(denimActivationTimestamp - av.L2_GENESIS_TIMESTAMP(), av.L2_BLOCK_TIME());
        (uint256 blockInterval, uint256 intermediateBlockInterval) = av.intervalsForStartingBlock(firstFastBlock - 1);
        require(blockInterval == av.SLOW_BLOCK_INTERVAL(), "pre-denim block interval mismatch");
        require(intermediateBlockInterval == av.SLOW_INTERMEDIATE_BLOCK_INTERVAL(), "pre-denim intermediate mismatch");
        (blockInterval, intermediateBlockInterval) = av.intervalsForStartingBlock(firstFastBlock);
        require(blockInterval == fastBlockInterval, "post-denim block interval mismatch");
        require(intermediateBlockInterval == fastIntermediateBlockInterval, "post-denim intermediate mismatch");
    }

    /// @dev Checks the new verifier's hashes and fast intervals against config and every other immutable
    ///      against the live verifier.
    function _assertNewVerifier() internal view {
        IAggregateVerifierV020 live = IAggregateVerifierV020(oldAggregateVerifier);
        AggregateVerifier av = AggregateVerifier(newAggregateVerifier);

        require(av.TEE_IMAGE_HASH() == teeImageHash, "tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHash, "zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHash, "zk aggregate hash mismatch");
        require(av.FAST_BLOCK_INTERVAL() == fastBlockInterval, "fast block interval mismatch");
        require(av.FAST_INTERMEDIATE_BLOCK_INTERVAL() == fastIntermediateBlockInterval, "fast intermediate mismatch");

        require(av.SLOW_BLOCK_INTERVAL() == live.BLOCK_INTERVAL(), "slow block interval mismatch");
        require(
            av.SLOW_INTERMEDIATE_BLOCK_INTERVAL() == live.INTERMEDIATE_BLOCK_INTERVAL(), "slow intermediate mismatch"
        );
        require(GameType.unwrap(av.gameType()) == GameType.unwrap(live.gameType()), "game type mismatch");
        require(address(av.anchorStateRegistry()) == live.anchorStateRegistry(), "asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == live.DISPUTE_GAME_FACTORY(), "dgf mismatch");
        require(address(av.DELAYED_WETH()) == live.DELAYED_WETH(), "delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == live.TEE_VERIFIER(), "tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == live.ZK_VERIFIER(), "zk verifier mismatch");
        require(av.CONFIG_HASH() == live.CONFIG_HASH(), "config hash mismatch");
        require(av.L2_CHAIN_ID() == live.L2_CHAIN_ID(), "l2 chain id mismatch");
        require(address(av.PROTOCOL_VERSIONS()) == live.PROTOCOL_VERSIONS(), "protocol versions mismatch");
        require(av.L2_GENESIS_BLOCK_NUMBER() == live.L2_GENESIS_BLOCK_NUMBER(), "genesis block mismatch");
        require(av.L2_GENESIS_TIMESTAMP() == live.L2_GENESIS_TIMESTAMP(), "genesis timestamp mismatch");
        require(av.L2_BLOCK_TIME() == live.L2_BLOCK_TIME(), "l2 block time mismatch");
    }

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
        require(deposits == 13, "unexpected deposit count");
    }

    function _assertL2Upgrade() internal {
        uint256 l1Fork = vm.activeFork();
        vm.selectFork(l2Fork);
        _assertL2Before();
        address aliasOwner = AddressAliasHelper.applyL1ToL2Alias(ownerSafe);
        address[13] memory proxies = _allProxies();
        address[13] memory impls;
        impls[0] = l2ToL1MessagePasserImpl;
        impls[1] = l1BlockImpl;
        impls[2] = sequencerFeeVaultImpl;
        impls[3] = baseFeeVaultImpl;
        impls[4] = l1FeeVaultImpl;
        address[8] memory extra = _extraImplementations();
        for (uint256 i; i < 8; i++) {
            impls[5 + i] = extra[i];
        }
        uint256[4] memory processed;
        for (uint256 i; i < 3; i++) {
            processed[i] = _uint(proxies[i + 2], "totalProcessed()");
        }
        processed[3] = _uint(VAULT, "totalProcessed()");
        uint256 nonce = _uint(MESSENGER, "messageNonce()");
        bytes32 sender = vm.load(MESSENGER, bytes32(uint256(204)));
        bytes[] memory calls = _l2Calls();
        for (uint256 i; i < 13; i++) {
            require(impls[i].code.length != 0, "implementation missing");
            vm.cool(ADMIN);
            vm.cool(proxies[i]);
            vm.cool(impls[i]);
            vm.cool(legacyMigrator);
            vm.coolSlot(ADMIN, bytes32(0));
            vm.coolSlot(ADMIN, IMPLEMENTATION_SLOT);
            vm.coolSlot(proxies[i], IMPLEMENTATION_SLOT);
            vm.coolSlot(proxies[i], ADMIN_SLOT);
            vm.coolSlot(proxies[i], INITIALIZABLE_SLOT);
            for (uint256 slot; slot <= 4; slot++) {
                vm.coolSlot(proxies[i], bytes32(slot));
            }
            vm.coolSlot(MESSENGER, bytes32(uint256(204)));
            vm.coolSlot(MESSENGER, bytes32(uint256(207)));
            vm.prank(aliasOwner);
            uint256 beforeGas = gasleft();
            (bool ok, bytes memory reason) = ADMIN.call{gas: L2_GAS_LIMIT}(calls[i]);
            uint256 used = beforeGas - gasleft();
            console.log("L2 cold call gas", i, used);
            if (!ok) assembly { revert(add(reason, 32), mload(reason)) }
            require(used * 3 <= uint256(L2_GAS_LIMIT) * 2, "L2 call lacks gas headroom");
        }
        _assertPredeploy(proxies[0], impls[0], L2_TO_L1_MESSAGE_PASSER_VERSION);
        _assertPredeploy(proxies[1], impls[1], L1_BLOCK_VERSION);
        for (uint256 i; i < 3; i++) {
            _assertFeeVault(proxies[i + 2], impls[i + 2]);
            require(_uint(proxies[i + 2], "totalProcessed()") == processed[i], "fee processed changed");
            require(vm.load(proxies[i + 2], INITIALIZABLE_SLOT) == bytes32(uint256(1)), "fee initializer mismatch");
        }
        _assertUpgrade(extra);
        require(_uint(VAULT, "totalProcessed()") == processed[3], "operator processed changed");
        require(_uint(MESSENGER, "messageNonce()") == nonce, "messenger nonce changed");
        require(vm.load(MESSENGER, bytes32(uint256(204))) == sender, "messenger sender changed");
        require(IL2ProxyAdmin(ADMIN).owner() == aliasOwner, "l2 owner changed");
        _assertBaseTime();
        vm.selectFork(l1Fork);
    }

    function _assertFeeVault(address proxy, address impl) internal view {
        _assertPredeploy(proxy, impl, FEE_VAULT_VERSION);
        IFeeVault vault = IFeeVault(payable(proxy));
        require(vault.recipient() == feeVaultRecipient, "fee vault recipient mismatch");
        require(vault.minWithdrawalAmount() == feeVaultMinWithdrawalAmount, "fee vault min withdrawal mismatch");
        require(vault.withdrawalNetwork() == feeVaultWithdrawalNetwork, "fee vault withdrawal network mismatch");
        require(_uint(proxy, "RECIPIENT()") == uint160(feeVaultRecipient), "legacy fee recipient mismatch");
        require(_uint(proxy, "MIN_WITHDRAWAL_AMOUNT()") == feeVaultMinWithdrawalAmount, "legacy fee minimum mismatch");
        require(
            _uint(proxy, "WITHDRAWAL_NETWORK()") == uint256(feeVaultWithdrawalNetwork), "legacy fee network mismatch"
        );
    }

    function _assertPredeploy(address proxy, address impl, string memory version) internal view {
        require(
            IL2ProxyAdmin(Predeploys.PROXY_ADMIN).getProxyImplementation(proxy) == impl,
            "predeploy implementation mismatch"
        );
        require(_eq(ISemver(proxy).version(), version), "predeploy version mismatch");
    }

    function _l2Calls() internal view returns (bytes[] memory calls) {
        bytes memory initializeFeeVault = abi.encodeCall(
            IFeeVault.initialize, (feeVaultRecipient, feeVaultMinWithdrawalAmount, feeVaultWithdrawalNetwork)
        );

        calls = new bytes[](13);
        calls[0] = abi.encodeCall(
            IL2ProxyAdmin.upgrade, (payable(Predeploys.L2_TO_L1_MESSAGE_PASSER), l2ToL1MessagePasserImpl)
        );
        calls[1] = abi.encodeCall(IL2ProxyAdmin.upgrade, (payable(Predeploys.L1_BLOCK_ATTRIBUTES), l1BlockImpl));
        calls[2] = abi.encodeCall(
            IL2ProxyAdmin.upgradeAndCall,
            (payable(Predeploys.SEQUENCER_FEE_WALLET), sequencerFeeVaultImpl, initializeFeeVault)
        );
        calls[3] = abi.encodeCall(
            IL2ProxyAdmin.upgradeAndCall, (payable(Predeploys.BASE_FEE_VAULT), baseFeeVaultImpl, initializeFeeVault)
        );
        calls[4] = abi.encodeCall(
            IL2ProxyAdmin.upgradeAndCall, (payable(Predeploys.L1_FEE_VAULT), l1FeeVaultImpl, initializeFeeVault)
        );
        bytes[] memory extra = _extraCalls(_extraImplementations());
        for (uint256 i; i < 8; i++) {
            calls[5 + i] = extra[i];
        }
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }

    function _divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    function _eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    address internal constant ADMIN = 0x4200000000000000000000000000000000000018;
    address internal constant FACTORY = 0x4200000000000000000000000000000000000017;
    address internal constant VAULT = 0x420000000000000000000000000000000000001b;
    address internal constant REGISTRY = 0x4200000000000000000000000000000000000020;
    address internal constant EAS_PROXY = 0x4200000000000000000000000000000000000021;
    address internal constant MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant ERC20_FACTORY = 0x4200000000000000000000000000000000000012;
    address internal constant ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;
    bytes32 internal constant INITIALIZABLE_SLOT = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    address internal immutable factoryBridge = vm.envAddress("FACTORY_BRIDGE");
    uint256 internal immutable remoteChainId = vm.envUint("REMOTE_CHAIN_ID");
    address internal immutable vaultRecipient = vm.envAddress("OPERATOR_FEE_VAULT_RECIPIENT");
    uint256 internal immutable vaultMinimum = vm.envUint("OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT");
    uint8 internal immutable vaultNetwork = uint8(vm.envUint("OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK"));
    address internal immutable l1Messenger = vm.envAddress("L1_CROSS_DOMAIN_MESSENGER");
    address internal immutable l1Bridge = vm.envAddress("L1_STANDARD_BRIDGE");
    address internal immutable erc20Bridge = vm.envAddress("ERC20_FACTORY_BRIDGE");
    address internal immutable l1ERC721Bridge = vm.envAddress("L1_ERC721_BRIDGE");

    address internal immutable legacyMigrator = vm.envAddress("LEGACY_MIGRATOR");

    function _migrator() internal view returns (address) {
        return legacyMigrator;
    }

    function _proxies() internal pure returns (address[8] memory) {
        return [FACTORY, VAULT, REGISTRY, EAS_PROXY, MESSENGER, BRIDGE, ERC20_FACTORY, ERC721_BRIDGE];
    }

    function _versions() internal pure returns (string[8] memory) {
        return [string("1.4.2"), "1.1.0", "1.3.1-beta.2", "1.4.1-beta.3", "2.2.0", "1.13.0", "1.10.2", "1.10.0"];
    }

    function _extraCalls(address[8] memory impls) internal view returns (bytes[] memory calls) {
        address[8] memory proxies = _proxies();
        calls = new bytes[](8);
        for (uint256 i; i < 4; i++) {
            calls[i] = abi.encodeCall(IL2ProxyAdmin.upgrade, (payable(proxies[i]), impls[i]));
        }
        address[4] memory counterparts = [l1Messenger, l1Bridge, erc20Bridge, l1ERC721Bridge];
        for (uint256 i; i < 4; i++) {
            calls[i + 4] = abi.encodeCall(
                IL2ProxyAdmin.upgradeAndCall,
                (
                    payable(proxies[i + 4]),
                    _migrator(),
                    abi.encodeCall(
                        LegacyMigrator.migrate,
                        (impls[i + 4], abi.encodeWithSignature("initialize(address)", counterparts[i]))
                    )
                )
            );
        }
        calls[1] = abi.encodeCall(
            IL2ProxyAdmin.upgradeAndCall,
            (
                payable(VAULT),
                impls[1],
                abi.encodeWithSignature("initialize(address,uint256,uint8)", vaultRecipient, vaultMinimum, vaultNetwork)
            )
        );
    }

    address internal immutable extraImpl0 = vm.envAddress("ERC721_FACTORY_IMPL");
    address internal immutable extraImpl1 = vm.envAddress("OPERATOR_FEE_VAULT_IMPL");
    address internal immutable extraImpl2 = vm.envAddress("SCHEMA_REGISTRY_IMPL");
    address internal immutable extraImpl3 = vm.envAddress("EAS_IMPL");
    address internal immutable extraImpl4 = vm.envAddress("MESSENGER_IMPL");
    address internal immutable extraImpl5 = vm.envAddress("BRIDGE_IMPL");
    address internal immutable extraImpl6 = vm.envAddress("ERC20_FACTORY_IMPL");
    address internal immutable extraImpl7 = vm.envAddress("ERC721_BRIDGE_IMPL");

    function _extraImplementations() internal view returns (address[8] memory) {
        return [extraImpl0, extraImpl1, extraImpl2, extraImpl3, extraImpl4, extraImpl5, extraImpl6, extraImpl7];
    }
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    address internal constant BASE_TIME = 0x4200000000000000000000000000000000000030;

    function _assertBaseTime() internal view {
        require(vm.load(BASE_TIME, IMPLEMENTATION_SLOT) == bytes32(0), "BaseTime already installed");
        require(uint256(vm.load(BASE_TIME, ADMIN_SLOT)) == uint160(ADMIN), "BaseTime admin mismatch");
    }

    function _allProxies() internal pure returns (address[13] memory result) {
        result[0] = Predeploys.L2_TO_L1_MESSAGE_PASSER;
        result[1] = Predeploys.L1_BLOCK_ATTRIBUTES;
        result[2] = Predeploys.SEQUENCER_FEE_WALLET;
        result[3] = Predeploys.BASE_FEE_VAULT;
        result[4] = Predeploys.L1_FEE_VAULT;
        address[8] memory extra = _proxies();
        for (uint256 i; i < 8; i++) {
            result[5 + i] = extra[i];
        }
    }

    function _assertL2Before() internal view {
        _assertBaseTime();
        require(IL2ProxyAdmin(ADMIN).owner() == AddressAliasHelper.applyL1ToL2Alias(ownerSafe), "l2 owner mismatch");
        string[13] memory versions = [
            string("1.0.0"),
            "1.7.0",
            "1.3.0",
            "1.3.0",
            "1.3.0",
            "1.2.0",
            "1.0.0",
            "1.0.1",
            "1.0.1",
            "1.4.0",
            "1.1.0",
            "1.9.0",
            "1.1.0"
        ];
        address[13] memory proxies = _allProxies();
        for (uint256 i; i < 13; i++) {
            require(_eq(ISemver(proxies[i]).version(), versions[i]), "legacy version changed");
            require(uint256(vm.load(proxies[i], ADMIN_SLOT)) == uint160(ADMIN), "proxy admin changed");
        }
        for (uint256 i = 2; i <= 4; i++) {
            require(_uint(proxies[i], "RECIPIENT()") == uint160(feeVaultRecipient), "live fee recipient changed");
            require(
                _uint(proxies[i], "MIN_WITHDRAWAL_AMOUNT()") == feeVaultMinWithdrawalAmount, "live fee minimum changed"
            );
            require(
                _uint(proxies[i], "WITHDRAWAL_NETWORK()") == uint256(feeVaultWithdrawalNetwork),
                "live fee network changed"
            );
            require(vm.load(proxies[i], INITIALIZABLE_SLOT) == bytes32(0), "fee vault initialized");
            require(
                vm.load(proxies[i], bytes32(uint256(1))) == bytes32(0)
                    && vm.load(proxies[i], bytes32(uint256(2))) == bytes32(0),
                "fee slots occupied"
            );
        }
        require(_uint(FACTORY, "BRIDGE()") == uint160(factoryBridge), "live factory bridge changed");
        require(_uint(FACTORY, "REMOTE_CHAIN_ID()") == remoteChainId, "live remote chain changed");
        require(vm.load(FACTORY, bytes32(0)) == bytes32(0), "ERC721 factory root slot changed");
        require(_uint(VAULT, "RECIPIENT()") == uint160(vaultRecipient), "live operator recipient changed");
        require(_uint(VAULT, "MIN_WITHDRAWAL_AMOUNT()") == vaultMinimum, "live operator minimum changed");
        require(_uint(VAULT, "WITHDRAWAL_NETWORK()") == vaultNetwork, "live operator network changed");
        require(vm.load(VAULT, INITIALIZABLE_SLOT) == bytes32(0), "operator vault initialized");
        require(
            vm.load(VAULT, bytes32(uint256(1))) == bytes32(0) && vm.load(VAULT, bytes32(uint256(2))) == bytes32(0),
            "operator slots occupied"
        );
        require(_uint(MESSENGER, "OTHER_MESSENGER()") == uint160(l1Messenger), "live L1 messenger changed");
        require(_uint(BRIDGE, "OTHER_BRIDGE()") == uint160(l1Bridge), "live L1 bridge changed");
        require(
            _uint(ERC20_FACTORY, "BRIDGE()") == uint160(erc20Bridge) && erc20Bridge == BRIDGE,
            "live ERC20 bridge changed"
        );
        require(_uint(ERC721_BRIDGE, "OTHER_BRIDGE()") == uint160(l1ERC721Bridge), "live L1 ERC721 bridge changed");
        require(uint256(vm.load(MESSENGER, bytes32(0))) == uint256(1) << 160, "messenger slot zero changed");
        require(vm.load(BRIDGE, bytes32(0)) == bytes32(0), "bridge slot zero changed");
        require(vm.load(ERC20_FACTORY, bytes32(0)) == bytes32(uint256(1)), "ERC20 slot zero changed");
        require(vm.load(ERC721_BRIDGE, bytes32(0)) == bytes32(0), "ERC721 slot zero changed");
        require(vm.load(MESSENGER, bytes32(uint256(204))) == bytes32(uint256(0xdead)), "messenger relaying");
        require(
            _uint(MESSENGER, "l1CrossDomainMessenger()") == uint160(l1Messenger), "legacy messenger counterpart changed"
        );
        require(_uint(BRIDGE, "MESSENGER()") == uint160(MESSENGER), "live bridge messenger changed");
        require(_uint(ERC721_BRIDGE, "MESSENGER()") == uint160(MESSENGER), "live ERC721 messenger changed");
        require(
            vm.load(ERC20_FACTORY, bytes32(uint256(1))) == bytes32(uint256(uint160(BRIDGE))),
            "ERC20 bridge slot changed"
        );
        require(
            vm.load(BRIDGE, bytes32(uint256(3))) == bytes32(0) && vm.load(BRIDGE, bytes32(uint256(4))) == bytes32(0),
            "bridge configuration slots occupied"
        );
        require(
            vm.load(ERC721_BRIDGE, bytes32(uint256(1))) == bytes32(0)
                && vm.load(ERC721_BRIDGE, bytes32(uint256(2))) == bytes32(0),
            "ERC721 configuration slots occupied"
        );
        require(vm.load(MESSENGER, bytes32(uint256(207))) == bytes32(0), "messenger counterpart slot occupied");
    }

    function _assertUpgrade(address[8] memory impls) internal view {
        address[8] memory proxies = _proxies();
        string[8] memory versions = _versions();
        for (uint256 i; i < 8; i++) {
            require(IL2ProxyAdmin(ADMIN).getProxyImplementation(proxies[i]) == impls[i], "implementation mismatch");
            require(
                keccak256(bytes(ISemver(proxies[i]).version())) == keccak256(bytes(versions[i])), "version mismatch"
            );
        }
        _assertConfiguration();
    }

    function _assertConfiguration() internal view {
        for (uint256 i = 4; i < 8; i++) {
            uint256 flags = uint256(vm.load(_proxies()[i], bytes32(0))) >> (i == 4 ? 160 : 0);
            require(uint8(flags) == 1 && uint8(flags >> 8) == 0, "migration initializer mismatch");
        }
        require(_uint(MESSENGER, "otherMessenger()") == uint160(l1Messenger), "messenger counterpart mismatch");
        require(_uint(MESSENGER, "OTHER_MESSENGER()") == uint160(l1Messenger), "legacy messenger counterpart mismatch");
        require(_uint(BRIDGE, "messenger()") == uint160(MESSENGER), "bridge messenger mismatch");
        require(_uint(BRIDGE, "otherBridge()") == uint160(l1Bridge), "bridge counterpart mismatch");
        require(_uint(BRIDGE, "OTHER_BRIDGE()") == uint160(l1Bridge), "legacy bridge counterpart mismatch");
        require(_uint(ERC20_FACTORY, "bridge()") == uint160(BRIDGE), "ERC20 bridge mismatch");
        require(_uint(ERC20_FACTORY, "BRIDGE()") == uint160(BRIDGE), "legacy ERC20 bridge mismatch");
        require(_uint(ERC721_BRIDGE, "messenger()") == uint160(MESSENGER), "ERC721 messenger mismatch");
        require(_uint(ERC721_BRIDGE, "otherBridge()") == uint160(l1ERC721Bridge), "ERC721 counterpart mismatch");
        require(_uint(ERC721_BRIDGE, "OTHER_BRIDGE()") == uint160(l1ERC721Bridge), "legacy ERC721 counterpart mismatch");
        require(_uint(ERC721_BRIDGE, "MESSENGER()") == uint160(MESSENGER), "legacy ERC721 messenger mismatch");
        require(_uint(BRIDGE, "MESSENGER()") == uint160(MESSENGER), "legacy bridge messenger mismatch");
        require(_uint(MESSENGER, "l1CrossDomainMessenger()") == uint160(l1Messenger), "legacy L1 messenger mismatch");
        require(_uint(FACTORY, "bridge()") == uint160(factoryBridge), "factory bridge mismatch");
        require(_uint(FACTORY, "BRIDGE()") == uint160(factoryBridge), "legacy factory bridge mismatch");
        require(_uint(FACTORY, "remoteChainID()") == remoteChainId, "remote chain mismatch");
        require(_uint(FACTORY, "REMOTE_CHAIN_ID()") == remoteChainId, "legacy remote chain mismatch");
        require(_uint(VAULT, "recipient()") == uint160(vaultRecipient), "operator recipient mismatch");
        require(_uint(VAULT, "minWithdrawalAmount()") == vaultMinimum, "operator minimum mismatch");
        require(_uint(VAULT, "withdrawalNetwork()") == vaultNetwork, "operator network mismatch");
        require(_uint(VAULT, "RECIPIENT()") == uint160(vaultRecipient), "legacy operator recipient mismatch");
        require(_uint(VAULT, "MIN_WITHDRAWAL_AMOUNT()") == vaultMinimum, "legacy operator minimum mismatch");
        require(_uint(VAULT, "WITHDRAWAL_NETWORK()") == vaultNetwork, "legacy operator network mismatch");
        require(vm.load(VAULT, INITIALIZABLE_SLOT) == bytes32(uint256(1)), "operator initializer mismatch");
        require(_uint(EAS_PROXY, "getSchemaRegistry()") == uint160(REGISTRY), "EAS registry mismatch");
    }

    function _uint(address target, string memory signature) internal view returns (uint256) {
        (bool ok, bytes memory data) = target.staticcall(abi.encodeWithSignature(signature));
        require(ok, signature);
        return abi.decode(data, (uint256));
    }
}
