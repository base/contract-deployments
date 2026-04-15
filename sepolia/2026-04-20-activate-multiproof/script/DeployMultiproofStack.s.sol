// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {INitroEnclaveVerifier} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";

import {GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {DelayedWETH} from "@base-contracts/src/dispute/DelayedWETH.sol";
import {DisputeGameFactory} from "@base-contracts/src/dispute/DisputeGameFactory.sol";
import {AnchorStateRegistry} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {OptimismPortal2} from "@base-contracts/src/L1/OptimismPortal2.sol";
import {TEEProverRegistry} from "@base-contracts/src/multiproof/tee/TEEProverRegistry.sol";
import {TEEVerifier} from "@base-contracts/src/multiproof/tee/TEEVerifier.sol";
import {AggregateVerifier} from "@base-contracts/src/multiproof/AggregateVerifier.sol";
import {MockVerifier} from "@base-contracts/src/multiproof/mocks/MockVerifier.sol";
import {Proxy} from "@base-contracts/src/universal/Proxy.sol";

interface IProxy {
    function implementation() external view returns (address);
}

contract DeployMultiproofStack is Script {
    // Existing L1 dependencies consumed by the deploy.
    address internal l1ProxyAdminEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;

    // Multiproof identity and chain-level parameters.
    uint32 internal gameTypeEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkRangeHashEnv;
    bytes32 internal zkAggregateHashEnv;
    bytes32 internal configHashEnv;
    uint256 internal l2ChainIdEnv;
    uint256 internal blockIntervalEnv;
    uint256 internal intermediateBlockIntervalEnv;
    uint256 internal proofThresholdEnv;

    // Delay / timing parameters for the newly deployed implementations.
    uint256 internal proofMaturityDelaySecondsEnv;
    uint256 internal disputeGameFinalityDelaySecondsEnv;
    uint256 internal delayedWethDelaySecondsEnv;

    // Proxy initialization parameters (TEEProverRegistry + DelayedWETH).
    address internal systemConfigEnv;
    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryManagerEnv;
    address internal proposerEnv;
    address internal challengerEnv;

    // Predeployed RISC Zero / Nitro contracts consumed by this task.
    address public nitroEnclaveVerifier;

    // Freshly deployed contracts / implementations produced by this task.
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
        // Existing L1 dependencies consumed by the deploy.
        l1ProxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        // Multiproof identity and chain-level parameters.
        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkRangeHashEnv = vm.envBytes32("ZK_RANGE_HASH");
        zkAggregateHashEnv = vm.envBytes32("ZK_AGGREGATE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");
        l2ChainIdEnv = vm.envUint("L2_CHAIN_ID");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");
        proofThresholdEnv = vm.envUint("PROOF_THRESHOLD");

        // Delay / timing parameters for the newly deployed implementations.
        proofMaturityDelaySecondsEnv = vm.envUint("PROOF_MATURITY_DELAY_SECONDS");
        disputeGameFinalityDelaySecondsEnv = vm.envUint("DISPUTE_GAME_FINALITY_DELAY_SECONDS");
        delayedWethDelaySecondsEnv = vm.envUint("DELAYED_WETH_DELAY_SECONDS");

        // Proxy initialization parameters (TEEProverRegistry + DelayedWETH).
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryManagerEnv = vm.envAddress("TEE_PROVER_REGISTRY_MANAGER");
        proposerEnv = vm.envAddress("PROPOSER");
        challengerEnv = vm.envAddress("CHALLENGER");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/addresses.json");
        string memory json = vm.readFile(path);
        nitroEnclaveVerifier = vm.parseJsonAddress({json: json, key: ".nitroEnclaveVerifier"});
    }

    function run() external {
        vm.startBroadcast();

        // 0. Deploy the TEE prover registry implementation.
        teeProverRegistryImpl = address(
            new TEEProverRegistry({
                nitroVerifier: INitroEnclaveVerifier(nitroEnclaveVerifier),
                factory: IDisputeGameFactory(disputeGameFactoryProxyEnv)
            })
        );

        // 1. Deploy the DelayedWETH implementation.
        delayedWethImpl = address(new DelayedWETH({_delay: delayedWethDelaySecondsEnv}));

        // 2. Deploy proxies with msg.sender as admin, initialize immediately,
        //    then transfer admin to the real ProxyAdmin.
        {
            // 2a. TEEProverRegistry proxy: deploy, upgradeToAndCall to initialize
            //     with the configured owner/manager/proposers/gameType, then hand
            //     the proxy admin to the real ProxyAdmin.
            address[] memory initialProposers = new address[](2);
            initialProposers[0] = proposerEnv;
            initialProposers[1] = challengerEnv;

            Proxy teeProxy = new Proxy(msg.sender);
            teeProxy.upgradeToAndCall(
                teeProverRegistryImpl,
                abi.encodeCall(
                    TEEProverRegistry.initialize,
                    (
                        teeProverRegistryOwnerEnv,
                        teeProverRegistryManagerEnv,
                        initialProposers,
                        GameType.wrap(gameTypeEnv)
                    )
                )
            );
            teeProxy.changeAdmin(l1ProxyAdminEnv);
            teeProverRegistryProxy = address(teeProxy);

            // 2b. DelayedWETH proxy: deploy, upgradeToAndCall to initialize with
            //     the existing SystemConfig, then hand the proxy admin to the real
            //     ProxyAdmin.
            Proxy wethProxy = new Proxy(msg.sender);
            wethProxy.upgradeToAndCall(
                delayedWethImpl, abi.encodeCall(DelayedWETH.initialize, (ISystemConfig(systemConfigEnv)))
            );
            wethProxy.changeAdmin(l1ProxyAdminEnv);
            delayedWethProxy = address(wethProxy);
        }

        // 3. Deploy the stateless TEE verifier.
        teeVerifier = address(
            new TEEVerifier({
                teeProverRegistry: TEEProverRegistry(teeProverRegistryProxy),
                anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)
            })
        );

        // 4. Deploy the temporary mock ZK verifier used by the AggregateVerifier template.
        zkVerifier = address(new MockVerifier({anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)}));

        // 5. Deploy the multiproof AggregateVerifier template.
        aggregateVerifier = address(
            new AggregateVerifier({
                gameType_: GameType.wrap(gameTypeEnv),
                anchorStateRegistry_: IAnchorStateRegistry(anchorStateRegistryProxyEnv),
                delayedWETH: IDelayedWETH(payable(delayedWethProxy)),
                teeVerifier: TEEVerifier(teeVerifier),
                zkVerifier: MockVerifier(zkVerifier),
                teeImageHash: teeImageHashEnv,
                zkHashes: AggregateVerifier.ZkHashes({rangeHash: zkRangeHashEnv, aggregateHash: zkAggregateHashEnv}),
                configHash: configHashEnv,
                l2ChainId: l2ChainIdEnv,
                blockInterval: blockIntervalEnv,
                intermediateBlockInterval: intermediateBlockIntervalEnv,
                proofThreshold: proofThresholdEnv
            })
        );

        // 6. Deploy the new implementations for existing L1 proxies.
        optimismPortal2Impl = address(new OptimismPortal2({_proofMaturityDelaySeconds: proofMaturityDelaySecondsEnv}));
        disputeGameFactoryImpl = address(new DisputeGameFactory());
        anchorStateRegistryImpl =
            address(new AnchorStateRegistry({_disputeGameFinalityDelaySeconds: disputeGameFinalityDelaySecondsEnv}));

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal {
        _checkTeeProverRegistryImpl();
        _checkTeeProverRegistryProxy();
        _checkTeeVerifier();
        _checkMockVerifier();
        _checkDelayedWethImpl();
        _checkDelayedWethProxy();
        _checkAggregateVerifier();
        _checkUpgradeTargetImpls();
    }

    /// @dev Validates the TEEProverRegistry **implementation** contract.
    ///      1. Check that NITRO_VERIFIER points to the deployed NitroEnclaveVerifier.
    ///      2. Check that DISPUTE_GAME_FACTORY points to the existing DGF proxy.
    function _checkTeeProverRegistryImpl() internal view {
        TEEProverRegistry impl = TEEProverRegistry(teeProverRegistryImpl);

        require(address(impl.NITRO_VERIFIER()) == nitroEnclaveVerifier, "registry nitro verifier mismatch");
        require(address(impl.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "registry dgf mismatch");
    }

    /// @dev Validates the TEEProverRegistry proxy after upgradeToAndCall.
    ///      1. Check that the proxy implementation is set to the deployed impl.
    ///      2. Check that owner is set to TEE_PROVER_REGISTRY_OWNER.
    ///      3. Check that manager is set to TEE_PROVER_REGISTRY_MANAGER.
    ///      4. Check that gameType is set to the multiproof game type.
    ///      5. Check that PROPOSER is flagged as valid.
    ///      6. Check that CHALLENGER is flagged as valid.
    function _checkTeeProverRegistryProxy() internal {
        vm.prank(l1ProxyAdminEnv);
        require(IProxy(teeProverRegistryProxy).implementation() == teeProverRegistryImpl, "tee registry impl mismatch");

        TEEProverRegistry registry = TEEProverRegistry(teeProverRegistryProxy);
        require(registry.owner() == teeProverRegistryOwnerEnv, "tee registry owner mismatch");
        require(registry.manager() == teeProverRegistryManagerEnv, "tee registry manager mismatch");
        require(GameType.unwrap(registry.gameType()) == gameTypeEnv, "tee registry game type mismatch");
        require(registry.isValidProposer(proposerEnv), "tee registry proposer mismatch");
        require(registry.isValidProposer(challengerEnv), "tee registry challenger mismatch");
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

    /// @dev Validates the MockVerifier used as the temporary ZK verifier placeholder.
    ///      1. Check that ANCHOR_STATE_REGISTRY points to the existing ASR proxy.
    function _checkMockVerifier() internal view {
        require(
            address(MockVerifier(zkVerifier).ANCHOR_STATE_REGISTRY()) == anchorStateRegistryProxyEnv,
            "mock verifier asr mismatch"
        );
    }

    /// @dev Validates the DelayedWETH **implementation** contract.
    ///      1. Check that delay matches DELAYED_WETH_DELAY_SECONDS.
    function _checkDelayedWethImpl() internal view {
        require(
            DelayedWETH(payable(delayedWethImpl)).delay() == delayedWethDelaySecondsEnv, "delayed weth delay mismatch"
        );
    }

    /// @dev Validates the DelayedWETH proxy after upgradeToAndCall.
    ///      1. Check that the proxy implementation is set to the deployed impl.
    ///      2. Check that systemConfig is initialized to the existing SystemConfig.
    function _checkDelayedWethProxy() internal {
        vm.prank(l1ProxyAdminEnv);
        require(IProxy(delayedWethProxy).implementation() == delayedWethImpl, "delayed weth impl mismatch");
        require(
            address(DelayedWETH(payable(delayedWethProxy)).systemConfig()) == systemConfigEnv,
            "delayed weth systemConfig mismatch"
        );
    }

    /// @dev Validates the AggregateVerifier template that the DisputeGameFactory will clone for new games.
    ///      1. Check that gameType matches the .env value.
    ///      2. Check that anchorStateRegistry points to the existing ASR proxy.
    ///      3. Check that DISPUTE_GAME_FACTORY is derived from the ASR's disputeGameFactory().
    ///      4. Check that DELAYED_WETH points to the deployed DelayedWETH proxy.
    ///      5. Check that TEE_VERIFIER points to the deployed TEEVerifier.
    ///      6. Check that ZK_VERIFIER points to the deployed MockVerifier.
    ///      7. Check that TEE_IMAGE_HASH matches the .env value.
    ///      8. Check that ZK_RANGE_HASH matches the .env value.
    ///      9. Check that ZK_AGGREGATE_HASH matches the .env value.
    ///      10. Check that CONFIG_HASH matches the .env value.
    ///      11. Check that L2_CHAIN_ID matches the .env value.
    ///      12. Check that BLOCK_INTERVAL matches the .env value.
    ///      13. Check that INTERMEDIATE_BLOCK_INTERVAL matches the .env value.
    ///      14. Check that PROOF_THRESHOLD matches the .env value.
    function _checkAggregateVerifier() internal view {
        AggregateVerifier av = AggregateVerifier(aggregateVerifier);

        require(GameType.unwrap(av.gameType()) == gameTypeEnv, "aggregate game type mismatch");
        require(address(av.anchorStateRegistry()) == anchorStateRegistryProxyEnv, "aggregate asr mismatch");
        require(address(av.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv, "aggregate dgf mismatch");
        require(address(av.DELAYED_WETH()) == delayedWethProxy, "aggregate delayed weth mismatch");
        require(address(av.TEE_VERIFIER()) == teeVerifier, "aggregate tee verifier mismatch");
        require(address(av.ZK_VERIFIER()) == zkVerifier, "aggregate zk verifier mismatch");
        require(av.TEE_IMAGE_HASH() == teeImageHashEnv, "aggregate tee image hash mismatch");
        require(av.ZK_RANGE_HASH() == zkRangeHashEnv, "aggregate zk range hash mismatch");
        require(av.ZK_AGGREGATE_HASH() == zkAggregateHashEnv, "aggregate zk aggregate hash mismatch");
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
        // Emit addresses for operator visibility and persist them for the activation script.
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

        _writeAddress({key: "nitroEnclaveVerifier", value: nitroEnclaveVerifier});
        _writeAddress({key: "teeProverRegistryImpl", value: teeProverRegistryImpl});
        _writeAddress({key: "teeProverRegistryProxy", value: teeProverRegistryProxy});
        _writeAddress({key: "teeVerifier", value: teeVerifier});
        _writeAddress({key: "zkVerifier", value: zkVerifier});
        _writeAddress({key: "delayedWETHImpl", value: delayedWethImpl});
        _writeAddress({key: "delayedWETHProxy", value: delayedWethProxy});
        _writeAddress({key: "aggregateVerifier", value: aggregateVerifier});
        _writeAddress({key: "optimismPortal2Impl", value: optimismPortal2Impl});
        _writeAddress({key: "disputeGameFactoryImpl", value: disputeGameFactoryImpl});
        _writeAddress({key: "anchorStateRegistryImpl", value: anchorStateRegistryImpl});
    }

    function _writeAddress(string memory key, address value) internal {
        vm.writeJson({json: vm.toString(value), path: "addresses.json", valueKey: string.concat(".", key)});
    }
}
