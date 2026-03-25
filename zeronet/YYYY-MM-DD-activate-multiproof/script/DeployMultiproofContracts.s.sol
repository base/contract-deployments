// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ISystemConfig} from "interfaces/L1/ISystemConfig.sol";
import {IAnchorStateRegistry} from "interfaces/dispute/IAnchorStateRegistry.sol";
import {IDelayedWETH} from "interfaces/dispute/IDelayedWETH.sol";
import {IDisputeGameFactory} from "interfaces/dispute/IDisputeGameFactory.sol";
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

contract DeployMultiproofContracts is Script {
    address internal systemConfigEnv;
    address internal l1ProxyAdminEnv;
    address internal anchorStateRegistryProxyEnv;
    address internal disputeGameFactoryProxyEnv;

    uint32 internal gameTypeEnv;
    bytes32 internal teeImageHashEnv;
    bytes32 internal zkImageHashEnv;
    bytes32 internal configHashEnv;

    uint256 internal l2ChainIdEnv;
    uint256 internal blockIntervalEnv;
    uint256 internal intermediateBlockIntervalEnv;
    uint256 internal proofThresholdEnv;
    uint256 internal proofMaturityDelaySecondsEnv;
    uint256 internal disputeGameFinalityDelaySecondsEnv;
    uint256 internal delayedWethDelaySecondsEnv;

    address internal teeProverRegistryOwnerEnv;
    address internal teeProverRegistryManagerEnv;
    address internal teeProposerEnv;
    address internal nitroEnclaveVerifierEnv;

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
        systemConfigEnv = vm.envAddress("SYSTEM_CONFIG");
        l1ProxyAdminEnv = vm.envAddress("L1_PROXY_ADMIN");
        anchorStateRegistryProxyEnv = vm.envAddress("ANCHOR_STATE_REGISTRY_PROXY");
        disputeGameFactoryProxyEnv = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");

        gameTypeEnv = uint32(vm.envUint("GAME_TYPE"));
        teeImageHashEnv = vm.envBytes32("TEE_IMAGE_HASH");
        zkImageHashEnv = vm.envBytes32("ZK_IMAGE_HASH");
        configHashEnv = vm.envBytes32("CONFIG_HASH");

        l2ChainIdEnv = vm.envUint("L2_CHAIN_ID");
        blockIntervalEnv = vm.envUint("BLOCK_INTERVAL");
        intermediateBlockIntervalEnv = vm.envUint("INTERMEDIATE_BLOCK_INTERVAL");
        proofThresholdEnv = vm.envUint("PROOF_THRESHOLD");
        proofMaturityDelaySecondsEnv = vm.envUint("PROOF_MATURITY_DELAY_SECONDS");
        disputeGameFinalityDelaySecondsEnv = vm.envUint("DISPUTE_GAME_FINALITY_DELAY_SECONDS");
        delayedWethDelaySecondsEnv = vm.envUint("DELAYED_WETH_DELAY_SECONDS");

        teeProverRegistryOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        teeProverRegistryManagerEnv = vm.envAddress("TEE_PROVER_REGISTRY_MANAGER");
        teeProposerEnv = vm.envAddress("TEE_PROPOSER");
        nitroEnclaveVerifierEnv = vm.envAddress("NITRO_ENCLAVE_VERIFIER");
    }

    function run() external {
        vm.startBroadcast();

        // 0. Deploy the TEE prover registry implementation and its fresh proxy.
        //    This is a brand new proxy, so we initialize owner/manager/proposer immediately
        //    and point it at the existing DisputeGameFactory proxy for image-hash lookups.
        teeProverRegistryImpl = address(
            new TEEProverRegistry({
                nitroVerifier: INitroEnclaveVerifier(nitroEnclaveVerifierEnv),
                factory: IDisputeGameFactory(disputeGameFactoryProxyEnv)
            })
        );
        teeProverRegistryProxy = address(
            new TransparentUpgradeableProxy({
                _logic: teeProverRegistryImpl,
                admin_: l1ProxyAdminEnv,
                _data: abi.encodeCall(
                    TEEProverRegistry.initialize,
                    (teeProverRegistryOwnerEnv, teeProverRegistryManagerEnv, teeProposerEnv, GameType.wrap(gameTypeEnv))
                )
            })
        );

        // 1. Deploy the stateless TEE verifier against the newly initialized registry.
        teeVerifier = address(
            new TEEVerifier({
                teeProverRegistry: TEEProverRegistry(teeProverRegistryProxy),
                anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)
            })
        );

        // 2. Deploy the temporary mock ZK verifier.
        //    The real ZK verifier is not available yet, so keep the mock explicit for now.
        zkVerifier = address(new MockVerifier({anchorStateRegistry: IAnchorStateRegistry(anchorStateRegistryProxyEnv)}));

        // 3. Deploy DelayedWETH and initialize its fresh proxy against the existing
        //    SystemConfig on Hoodi L1.
        delayedWethImpl = address(new DelayedWETH({_delay: delayedWethDelaySecondsEnv}));
        delayedWethProxy = address(
            new TransparentUpgradeableProxy({
                _logic: delayedWethImpl,
                admin_: l1ProxyAdminEnv,
                _data: abi.encodeCall(DelayedWETH.initialize, (ISystemConfig(systemConfigEnv)))
            })
        );

        // 4. Deploy the multiproof AggregateVerifier that ties together the TEE verifier,
        //    the temporary ZK verifier, DelayedWETH, and the existing ASR proxy.
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

        // 5. Deploy the new implementations that will later be wired into the existing
        //    L1 proxies during the signed upgrade/cutover step.
        optimismPortal2Impl = address(new OptimismPortal2({_proofMaturityDelaySeconds: proofMaturityDelaySecondsEnv}));
        disputeGameFactoryImpl = address(new DisputeGameFactory());
        anchorStateRegistryImpl =
            address(new AnchorStateRegistry({_disputeGameFinalityDelaySeconds: disputeGameFinalityDelaySecondsEnv}));

        vm.stopBroadcast();

        _postCheck();
        _writeAddresses();
    }

    function _postCheck() internal view {
        // Sanity check the freshly deployed contracts before persisting addresses for the
        // follow-up upgrade script.
        require(
            TEEProverRegistry(teeProverRegistryProxy).owner() == teeProverRegistryOwnerEnv, "registry owner mismatch"
        );
        require(
            address(TEEProverRegistry(teeProverRegistryProxy).DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxyEnv,
            "registry dgf mismatch"
        );
        require(
            GameType.unwrap(TEEProverRegistry(teeProverRegistryProxy).gameType()) == gameTypeEnv,
            "registry game type mismatch"
        );
        require(TEEProverRegistry(teeProverRegistryProxy).isValidProposer(teeProposerEnv), "tee proposer mismatch");
        require(DelayedWETH(payable(delayedWethProxy)).delay() == delayedWethDelaySecondsEnv, "delayed weth mismatch");
        require(AggregateVerifier(aggregateVerifier).L2_CHAIN_ID() == l2ChainIdEnv, "aggregate l2 chain mismatch");
        require(
            AggregateVerifier(aggregateVerifier).BLOCK_INTERVAL() == blockIntervalEnv,
            "aggregate block interval mismatch"
        );
        require(
            AggregateVerifier(aggregateVerifier).INTERMEDIATE_BLOCK_INTERVAL() == intermediateBlockIntervalEnv,
            "aggregate intermediate interval mismatch"
        );
        require(
            AggregateVerifier(aggregateVerifier).PROOF_THRESHOLD() == proofThresholdEnv,
            "aggregate proof threshold mismatch"
        );
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
        string memory json = vm.serializeAddress(root, "teeProverRegistryImpl", teeProverRegistryImpl);
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
