// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {
    INitroEnclaveVerifier,
    ZkCoProcessorConfig,
    ZkCoProcessorType
} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {DelayedWETH} from "@base-contracts/src/dispute/DelayedWETH.sol";
import {DisputeGameFactory} from "@base-contracts/src/dispute/DisputeGameFactory.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {MockVerifier} from "@base-contracts/src/multiproof/mocks/MockVerifier.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

contract DeployMultiproofContracts is Script {
    // Existing Hoodi L1 dependencies consumed by the deploy.
    address internal l1ProxyAdminEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;

    // Multiproof identity and chain-level parameters.
    uint32 internal gameTypeEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkImageHashEnv;
    bytes32 internal configHashEnv;
    uint256 internal l2ChainIdEnv;
    uint256 internal blockIntervalEnv;
    uint256 internal intermediateBlockIntervalEnv;
    uint256 internal proofThresholdEnv;

    // Delay / timing parameters for the newly deployed implementations.
    uint256 internal proofMaturityDelaySecondsEnv;
    uint256 internal disputeGameFinalityDelaySecondsEnv;
    uint256 internal delayedWethDelaySecondsEnv;

    // NitroEnclaveVerifier constructor configuration.
    address internal teeProverRegistryOwnerEnv;
    uint64 internal nitroInitialMaxTimeDiffSecondsEnv;
    bytes32 internal nitroInitialTrustedIntermediateCertEnv;
    bytes32 internal nitroInitialRootCertEnv;
    ZkCoProcessorType internal nitroZkCoProcessorEnv;
    address internal nitroZkVerifierEnv;
    bytes32 internal nitroZkVerifierIdEnv;
    bytes32 internal nitroZkAggregatorIdEnv;
    bytes32 internal nitroZkVerifierProofIdEnv;

    // Freshly deployed contracts / implementations produced by this task.
    address public nitroEnclaveVerifier;
    address public teeProverRegistryImpl;
    address public teeProverRegistryProxy;
    address public teeVerifier;
    address public zkVerifier;
    address public delayedWethImpl;
    address public delayedWethProxy;
    address public aggregateVerifier;
    address public optimismPortal2Impl;
    address public disputeGameFactoryImpl;
    address public anchorStateRegistryImpl;

    function setUp() public {
        // Existing Hoodi L1 dependencies consumed by the deploy.
        l1ProxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        // Multiproof identity and chain-level parameters.
        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkImageHashEnv = vm.envBytes32("ZK_IMAGE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");
        l2ChainIdEnv = vm.envUint("L2_CHAIN_ID");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");
        proofThresholdEnv = vm.envUint("PROOF_THRESHOLD");

        // Delay / timing parameters for the newly deployed implementations.
        proofMaturityDelaySecondsEnv = vm.envUint("PROOF_MATURITY_DELAY_SECONDS");
        disputeGameFinalityDelaySecondsEnv = vm.envUint("DISPUTE_GAME_FINALITY_DELAY_SECONDS");
        delayedWethDelaySecondsEnv = vm.envUint("DELAYED_WETH_DELAY_SECONDS");

        // NitroEnclaveVerifier constructor configuration.
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        nitroInitialMaxTimeDiffSecondsEnv = uint64(vm.envUint("NITRO_INITIAL_MAX_TIME_DIFF_SECONDS"));
        nitroInitialTrustedIntermediateCertEnv = vm.envBytes32("NITRO_INITIAL_TRUSTED_INTERMEDIATE_CERT");
        nitroInitialRootCertEnv = vm.envBytes32("NITRO_INITIAL_ROOT_CERT");
        nitroZkCoProcessorEnv = ZkCoProcessorType(uint8(vm.envUint("NITRO_ZK_COPROCESSOR")));
        nitroZkVerifierEnv = vm.envAddress("NITRO_ZK_VERIFIER");
        nitroZkVerifierIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_ID");
        nitroZkAggregatorIdEnv = vm.envBytes32("NITRO_ZK_AGGREGATOR_ID");
        nitroZkVerifierProofIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_PROOF_ID");
    }

    function run() external {
        vm.startBroadcast();

        // 0. Deploy empty proxies with the real ProxyAdmin as admin.
        //    No implementation is set yet; the multisig upgrade script will wire
        //    them via ProxyAdmin.upgradeAndCall.
        teeProverRegistryProxy = address(new Proxy(l1ProxyAdminEnv));
        delayedWethProxy = address(new Proxy(l1ProxyAdminEnv));

        // 1. Deploy NitroEnclaveVerifier with TEE registry proxy address as proof submitter.
        bytes32[] memory initializeTrustedCerts = new bytes32[](1);
        initializeTrustedCerts[0] = nitroInitialTrustedIntermediateCertEnv;
        nitroEnclaveVerifier = address(
            new NitroEnclaveVerifier({
                owner: teeProverRegistryOwnerEnv,
                initialMaxTimeDiff: nitroInitialMaxTimeDiffSecondsEnv,
                initializeTrustedCerts: initializeTrustedCerts,
                initialRootCert: nitroInitialRootCertEnv,
                initialProofSubmitter: teeProverRegistryProxy,
                zkCoProcessor: nitroZkCoProcessorEnv,
                config: ZkCoProcessorConfig({
                    verifierId: nitroZkVerifierIdEnv,
                    aggregatorId: nitroZkAggregatorIdEnv,
                    zkVerifier: nitroZkVerifierEnv
                }),
                verifierProofId: nitroZkVerifierProofIdEnv
            })
        );

        // 2. Deploy the TEE prover registry implementation.
        teeProverRegistryImpl = address(
            new TEEProverRegistry({
                nitroVerifier: INitroEnclaveVerifier(nitroEnclaveVerifier),
                factory: IDisputeGameFactory(disputeGameFactoryProxyEnv)
            })
        );

        // 3. Deploy the stateless TEE verifier.
        teeVerifier = address(
            new TEEVerifier({
                teeProverRegistry: TEEProverRegistry(teeProverRegistryProxy),
                anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)
            })
        );

        // 4. Deploy the temporary mock ZK verifier.
        zkVerifier = address(new MockVerifier({anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)}));

        // 5. Deploy DelayedWETH implementation.
        delayedWethImpl = address(new DelayedWETH({_delay: delayedWethDelaySecondsEnv}));

        // 6. Deploy the multiproof AggregateVerifier.
        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: GameType.wrap(gameTypeEnv),
                anchorStateRegistry_: IAnchorStateRegistry(anchorStateRegistryProxyEnv),
                delayedWETH: IDelayedWETH(payable(delayedWethProxy)),
                teeVerifier: TEEVerifier(teeVerifier),
                zkVerifier: MockVerifier(zkVerifier),
                teeImageHash: teeImageHashEnv,
                zkImageHash: zkImageHashEnv,
                configHash: configHashEnv,
                l2ChainId: l2ChainIdEnv,
                blockInterval: blockIntervalEnv,
                intermediateBlockInterval: intermediateBlockIntervalEnv,
                proofThreshold: proofThresholdEnv
            })
        );

        // 7. Deploy the new implementations for existing L1 proxies.
        optimismPortal2Impl = address(new OptimismPortal2({_proofMaturityDelaySeconds: proofMaturityDelaySecondsEnv}));
        disputeGameFactoryImpl = address(new DisputeGameFactory());
        anchorStateRegistryImpl =
            address(new AnchorStateRegistry({_disputeGameFinalityDelaySeconds: disputeGameFinalityDelaySecondsEnv}));

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        _checkNitroEnclaveVerifier();
        _checkTeeProverRegistryImpl();
        _checkTeeVerifier();
        _checkMockVerifier();
        _checkDelayedWethImpl();
        _checkAggregateVerifier();
        _checkUpgradeTargetImpls();
    }

    /// @dev Validates the NitroEnclaveVerifier deployment. This is a standalone contract
    ///      (not behind a proxy), so all constructor-set state is readable immediately.
    ///      1. Check that owner is set to TEE_PROVER_REGISTRY_OWNER.
    ///      2. Check that maxTimeDiff matches NITRO_INITIAL_MAX_TIME_DIFF_SECONDS.
    ///      3. Check that rootCert matches NITRO_INITIAL_ROOT_CERT.
    ///      4. Check that proofSubmitter points to the TEEProverRegistry proxy.
    ///      5. Check that the trusted intermediate cert from .env is registered.
    ///      6. Check that the ZK coprocessor config (verifierId, aggregatorId, zkVerifier) and verifierProofId match the .env values.
    function _checkNitroEnclaveVerifier() internal view {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifier);

        require(nev.owner() == teeProverRegistryOwnerEnv, "nitro owner mismatch");
        require(nev.maxTimeDiff() == nitroInitialMaxTimeDiffSecondsEnv, "nitro max time diff mismatch");
        require(nev.rootCert() == nitroInitialRootCertEnv, "nitro root cert mismatch");
        require(nev.proofSubmitter() == teeProverRegistryProxy, "nitro proof submitter mismatch");
        require(
            nev.trustedIntermediateCerts(nitroInitialTrustedIntermediateCertEnv),
            "nitro trusted intermediate cert not registered"
        );

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(nitroZkCoProcessorEnv);
        require(cfg.verifierId == nitroZkVerifierIdEnv, "nitro verifier id mismatch");
        require(cfg.aggregatorId == nitroZkAggregatorIdEnv, "nitro aggregator id mismatch");
        require(cfg.zkVerifier == nitroZkVerifierEnv, "nitro zk verifier mismatch");
        require(
            nev.getVerifierProofId(nitroZkCoProcessorEnv, nitroZkVerifierIdEnv) == nitroZkVerifierProofIdEnv,
            "nitro verifier proof id mismatch"
        );
    }

    /// @dev Validates the TEEProverRegistry **implementation** contract. The proxy is
    ///      deployed empty (no implementation set); only constructor immutables are
    ///      readable on the implementation. Initialized state is checked in the upgrade script.
    ///      1. Check that NITRO_VERIFIER points to the deployed NitroEnclaveVerifier.
    ///      2. Check that DISPUTE_GAME_FACTORY points to the existing DGF proxy.
    function _checkTeeProverRegistryImpl() internal view {
        TEEProverRegistry impl = TEEProverRegistry(teeProverRegistryImpl);

        require(address(impl.NITRO_VERIFIER()) == nitroEnclaveVerifier, "registry nitro verifier mismatch");
        require(address(impl.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "registry dgf mismatch");
    }

    /// @dev Validates the TEEVerifier contract. This is a stateless verifier whose
    ///      immutables must reference the correct registry proxy and ASR proxy.
    ///      1. Check that TEE_PROVER_REGISTRY points to the deployed TEEProverRegistry proxy.
    ///      2. Check that ANCHOR_STATE_REGISTRY points to the existing ASR proxy.
    function _checkTeeVerifier() internal view {
        require(
            address(TEEVerifier(teeVerifier).TEE_PROVER_REGISTRY()) == teeProverRegistryProxy,
            "tee verifier registry mismatch"
        );
        require(
            address(TEEVerifier(teeVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "tee verifier asr mismatch"
        );
    }

    /// @dev Validates the MockVerifier (temporary ZK verifier placeholder).
    ///      1. Check that ANCHOR_STATE_REGISTRY points to the existing ASR proxy.
    function _checkMockVerifier() internal view {
        require(
            address(MockVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "mock verifier asr mismatch"
        );
    }

    /// @dev Validates the DelayedWETH **implementation** contract. Like the TEE registry,
    ///      the proxy is empty at this stage; initialization is deferred to the upgrade script.
    ///      1. Check that delay matches DELAYED_WETH_DELAY_SECONDS.
    function _checkDelayedWethImpl() internal view {
        require(
            DelayedWETH(payable(delayedWethImpl)).delay() == delayedWethDelaySecondsEnv, "delayed weth delay mismatch"
        );
    }

    /// @dev Validates the AggregateVerifier (EIP-1167 clone template for dispute games).
    ///      1. Check that gameType matches the .env value.
    ///      2. Check that anchorStateRegistry points to the existing ASR proxy.
    ///      3. Check that DISPUTE_GAME_FACTORY is derived from the ASR's disputeGameFactory().
    ///      4. Check that DELAYED_WETH points to the deployed DelayedWETH proxy.
    ///      5. Check that TEE_VERIFIER points to the deployed TEEVerifier.
    ///      6. Check that ZK_VERIFIER points to the deployed MockVerifier.
    ///      7. Check that TEE_IMAGE_HASH matches the .env value.
    ///      8. Check that ZK_IMAGE_HASH matches the .env value.
    ///      9. Check that CONFIG_HASH matches the .env value.
    ///      10. Check that L2_CHAIN_ID matches the .env value.
    ///      11. Check that BLOCK_INTERVAL matches the .env value.
    ///      12. Check that INTERMEDIATE_BLOCK_INTERVAL matches the .env value.
    ///      13. Check that PROOF_THRESHOLD matches the .env value.
    function _checkAggregateVerifier() internal view {
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(GameType.unwrap(av.gameType()) == gameTypeEnv, "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "aggregate asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "aggregate dgf mismatch");
        require(address(av.DELAYED_WETH()) == delayedWethProxy, "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == teeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == zkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_IMAGE_HASH() == zkImageHashEnv, "aggregate zk image hash mismatch");
        require(av.CONFIG_HASH() == configHashEnv, "aggregate config hash mismatch");
        require(av.L2_CHAIN_ID() == l2ChainIdEnv, "aggregate l2 chain mismatch");
        require(av.BLOCK_INTERVAL() == blockIntervalEnv, "aggregate block interval mismatch");
        require(av.INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockIntervalEnv, "aggregate intermediate mismatch");
        require(av.PROOF_THRESHOLD() == proofThresholdEnv, "aggregate proof threshold mismatch");
    }

    /// @dev Validates the new implementations for the existing L1 proxies.
    ///      1. Check that OptimismPortal2 proofMaturityDelaySeconds matches the .env value.
    ///      2. Check that AnchorStateRegistry disputeGameFinalityDelaySeconds matches the .env value.
    function _checkUpgradeTargetImpls() internal view {
        require(
            OptimismPortal2(payable(optimismPortal2Impl)).proofMaturityDelaySeconds() == proofMaturityDelaySecondsEnv,
            "portal delay mismatch"
        );
        require(
            AnchorStateRegistry(anchorStateRegistryImpl).disputeGameFinalityDelaySeconds()
                == disputeGameFinalityDelaySecondsEnv,
            "asr finality delay mismatch"
        );
    }

    function _writeAddresses() internal {
        // Emit addresses for operator visibility and persist them for the upgrade script.
        console.log("NitroEnclaveVerifier:", nitroEnclaveVerifier);
        console.log("TEEProverRegistry impl:", teeProverRegistryImpl);
        console.log("TEEProverRegistry proxy:", teeProverRegistryProxy);
        console.log("TEEVerifier:", teeVerifier);
        console.log("Mock ZKVerifier:", zkVerifier);
        console.log("DelayedWETH impl:", delayedWethImpl);
        console.log("DelayedWETH proxy:", delayedWethProxy);
        console.log("AggregateVerifier:", aggregateVerifier);
        console.log("OptimismPortal2 impl:", optimismPortal2Impl);
        console.log("DisputeGameFactory impl (no init bump required):", disputeGameFactoryImpl);
        console.log("AnchorStateRegistry impl:", anchorStateRegistryImpl);

        string memory root = "root";
        string memory json = vm.serializeAddress(root, "nitroEnclaveVerifier", nitroEnclaveVerifier);
        json = vm.serializeAddress(root, "teeProverRegistryImpl", teeProverRegistryImpl);
        json = vm.serializeAddress(root, "teeProverRegistryProxy", teeProverRegistryProxy);
        json = vm.serializeAddress(root, "teeVerifier", teeVerifier);
        json = vm.serializeAddress(root, "zkVerifier", zkVerifier);
        json = vm.serializeAddress(root, "delayedWETHImpl", delayedWethImpl);
        json = vm.serializeAddress(root, "delayedWETHProxy", delayedWethProxy);
        json = vm.serializeAddress(root, "aggregateVerifier", aggregateVerifier);
        json = vm.serializeAddress(root, "optimismPortal2Impl", optimismPortal2Impl);
        json = vm.serializeAddress(root, "disputeGameFactoryImpl", disputeGameFactoryImpl);
        json = vm.serializeAddress(root, "anchorStateRegistryImpl", anchorStateRegistryImpl);
        vm.writeJson(json, "addresses.json");
    }
}
