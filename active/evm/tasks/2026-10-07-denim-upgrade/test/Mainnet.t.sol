// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {AggregateVerifier} from "@base-contracts/src/L1/proofs/AggregateVerifier.sol";
import {DeployDenimProofImpls} from "../script/DeployDenimProofImpls.s.sol";
import {ExecuteDenimUpgradeWithAllL2Predeploys} from "../script/ExecuteDenimUpgradeWithAllL2Predeploys.s.sol";

contract VerifierFixture is DeployDenimProofImpls {
    function deploy() external returns (address) {
        return address(
            new AggregateVerifier(
                gameType,
                anchorStateRegistry,
                delayedWeth,
                teeVerifier,
                zkVerifier,
                teeImageHash,
                _zkHashes(),
                configHash,
                l2ChainId,
                _intervalConfig(),
                _scheduleConfig()
            )
        );
    }
}

contract RevertingInitializer {
    function initialize(address) external {
        assembly { sstore(0, 999) }
        revert("initializer failed");
    }

    function initialize(address, uint256, uint8) external {
        assembly { sstore(1, 999) }
        revert("initializer failed");
    }
}

contract MainnetHarness is ExecuteDenimUpgradeWithAllL2Predeploys {
    constructor() {
        vm.rollFork(l2Fork, 52953400);
    }

    function l2ForkId() external view returns (uint256) {
        return l2Fork;
    }

    function replay() external {
        _assertL2Upgrade(_l2Calls());
    }

    function l2Calls() external view returns (bytes[] memory, uint64) {
        return (_l2Calls(), L2_GAS_LIMIT);
    }

    function checkDeposits(Vm.AccountAccess[] memory accesses) external view returns (bytes[] memory) {
        return _assertDeposits(accesses);
    }

    function depositAccesses() external view returns (Vm.AccountAccess[] memory accesses) {
        Call[] memory calls = _buildCalls();
        accesses = new Vm.AccountAccess[](13);
        for (uint256 i; i < 13; i++) {
            accesses[i].account = optimismPortal;
            accesses[i].accessor = ownerSafe;
            accesses[i].kind = VmSafe.AccountAccessKind.Call;
            accesses[i].data = calls[i + 2].data;
        }
    }

    function simulateForTest() external {
        require(_buildCalls().length == 15, "mainnet must contain fifteen calls");
        address[] memory safes = new address[](1);
        safes[0] = ownerSafe;
        uint256 snapshot = vm.snapshotState();
        uint256 beforeGas = gasleft();
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory payload) =
            _simulateForSigner(safes, _buildCallsChain(safes));
        uint256 used = beforeGas - gasleft();
        console.log("L1 signer simulation gas including instrumentation", used);
        require(used < 12_000_000, "owner transaction lacks gas headroom");
        _postCheck(accesses, payload);
        require(vm.revertToState(snapshot), "simulation restore failed");
    }

    function prepareOwnerTransaction() external returns (address, bytes memory) {
        address[] memory safes = new address[](1);
        safes[0] = ownerSafe;
        Call memory call = _buildCallsChain(safes)[0];
        address base = vm.envAddress("CB_MULTISIG");
        address council = vm.envAddress("BASE_SECURITY_COUNCIL");
        bytes32 hash = _getTransactionHash(ownerSafe, call);
        vm.store(ownerSafe, Simulation.computeApprovedHashSlot(base, hash), bytes32(uint256(1)));
        vm.store(ownerSafe, Simulation.computeApprovedHashSlot(council, hash), bytes32(uint256(1)));
        require(vm.load(ownerSafe, bytes32(uint256(4))) == bytes32(uint256(2)), "owner threshold changed");
        require(council < base, "signature order changed");
        bytes memory signatures = abi.encodePacked(
            bytes32(uint256(uint160(council))),
            bytes32(0),
            uint8(1),
            bytes32(uint256(uint160(base))),
            bytes32(0),
            uint8(1)
        );
        Call memory execution = _buildExecTransactionCall(ownerSafe, call, signatures);
        return (ownerSafe, execution.data);
    }
}

contract MainnetTest is Script {
    address internal constant ADMIN = 0x4200000000000000000000000000000000000018;
    address[13] internal proxies = [
        address(0x4200000000000000000000000000000000000016),
        0x4200000000000000000000000000000000000015,
        0x4200000000000000000000000000000000000011,
        0x4200000000000000000000000000000000000019,
        0x420000000000000000000000000000000000001A,
        0x4200000000000000000000000000000000000017,
        0x420000000000000000000000000000000000001b,
        0x4200000000000000000000000000000000000020,
        0x4200000000000000000000000000000000000021,
        0x4200000000000000000000000000000000000007,
        0x4200000000000000000000000000000000000010,
        0x4200000000000000000000000000000000000012,
        0x4200000000000000000000000000000000000014
    ];
    address[13] internal implementations;
    uint256 internal l2;

    struct PreservedState {
        bytes32[9] blockAttributes;
        bytes32[206] messengerState;
        bytes easNonce;
    }

    function _deploy(string memory artifact, bytes memory args) internal returns (address deployed) {
        bytes memory code = abi.encodePacked(vm.getCode(artifact), args);
        assembly { deployed := create(0, add(code, 32), mload(code)) }
        require(deployed != address(0), "fixture deployment failed");
        vm.makePersistent(deployed);
    }

    function setUp() public {
        l2 = vm.createSelectFork(vm.envString("L2_RPC_URL"), 52953400);
        string[13] memory artifacts = [
            string("L2ToL1MessagePasser"),
            "L1Block",
            "SequencerFeeVault",
            "BaseFeeVault",
            "L1FeeVault",
            "OptimismMintableERC721Factory",
            "OperatorFeeVault",
            "SchemaRegistry",
            "EAS",
            "L2CrossDomainMessenger",
            "L2StandardBridge",
            "OptimismMintableERC20Factory",
            "L2ERC721Bridge"
        ];
        string[13] memory keys = [
            string("L2_TO_L1_MESSAGE_PASSER_IMPL"),
            "L1_BLOCK_IMPL",
            "SEQUENCER_FEE_VAULT_IMPL",
            "BASE_FEE_VAULT_IMPL",
            "L1_FEE_VAULT_IMPL",
            "ERC721_FACTORY_IMPL",
            "OPERATOR_FEE_VAULT_IMPL",
            "SCHEMA_REGISTRY_IMPL",
            "EAS_IMPL",
            "MESSENGER_IMPL",
            "BRIDGE_IMPL",
            "ERC20_FACTORY_IMPL",
            "ERC721_BRIDGE_IMPL"
        ];
        for (uint256 i; i < 13; i++) {
            implementations[i] = _deploy(
                string.concat(artifacts[i], ".sol:", artifacts[i]),
                i == 5 ? abi.encode(proxies[12], uint256(1)) : bytes("")
            );
            vm.setEnv(keys[i], vm.toString(implementations[i]));
        }
        address migrator = _deploy("LegacyMigrator.sol:LegacyMigrator", "");
        vm.setEnv("LEGACY_MIGRATOR", vm.toString(migrator));
        vm.setEnv("AGGREGATE_VERIFIER_TEE_IMAGE_HASH", vm.toString(bytes32(uint256(1))));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_RANGE_HASH", vm.toString(bytes32(uint256(2))));
        vm.setEnv("AGGREGATE_VERIFIER_ZK_AGGREGATE_HASH", vm.toString(bytes32(uint256(3))));
        vm.createSelectFork(vm.envString("L1_RPC_URL"), 26250153);
        VerifierFixture fixture = new VerifierFixture();
        fixture.setUp();
        address verifier = fixture.deploy();
        vm.makePersistent(verifier);
        vm.setEnv("NEW_AGGREGATE_VERIFIER", vm.toString(verifier));
    }

    function _upgradeL2() internal returns (MainnetHarness upgrade) {
        upgrade = new MainnetHarness();
        vm.makePersistent(address(upgrade));
        vm.selectFork(upgrade.l2ForkId());
    }

    function _read(address target, bytes memory data) internal view returns (bytes memory result) {
        bool ok;
        (ok, result) = target.staticcall(data);
        require(ok, "record read failed");
    }

    function _intrinsicGas(bytes memory data) internal pure returns (uint256 gas) {
        gas = 21_000;
        for (uint256 i; i < data.length; i++) {
            gas += data[i] == 0 ? 4 : 16;
        }
    }

    function testColdL2DepositGas() public {
        MainnetHarness upgrade = _upgradeL2();
        (bytes[] memory calls, uint64 limit) = upgrade.l2Calls();
        address aliasOwner = 0x8cC51c3008b3f03Fe483B28B8Db90e19cF076a6d;
        for (uint256 i; i < calls.length; i++) {
            uint256 intrinsic = _intrinsicGas(calls[i]);
            vm.prank(aliasOwner);
            uint256 beforeGas = gasleft();
            (bool ok,) = ADMIN.call{gas: limit - intrinsic}(calls[i]);
            // Isolated calls charge intrinsic gas and deduct refunds from gasleft().
            uint256 total = beforeGas - gasleft();
            Vm.Gas memory measured = vm.lastCallGas();
            if (measured.gasRefunded > 0) total += uint64(measured.gasRefunded);
            uint256 execution = total - intrinsic;
            require(ok, "cold deposit failed");
            if (i == 0) require(execution > 20_000, "gas measurement is not cold; use --isolate");
            console.log("L2 cold execution gas", i, execution);
            console.log("L2 intrinsic gas", i, intrinsic);
            console.log("L2 total gas", i, execution + intrinsic);
            require((execution + intrinsic) * 3 <= uint256(limit) * 2, "L2 deposit lacks gas headroom");
        }
    }

    function testColdL1OwnerTransactionGas() public {
        MainnetHarness upgrade = new MainnetHarness();
        upgrade.setUp();
        (address owner, bytes memory data) = upgrade.prepareOwnerTransaction();
        uint256 beforeGas = gasleft();
        (bool ok, bytes memory result) = owner.call{gas: 12_000_000}(data);
        // Isolation already includes transaction intrinsic gas in the charged gas.
        uint256 total = beforeGas - gasleft();
        Vm.Gas memory measured = vm.lastCallGas();
        if (measured.gasRefunded > 0) total += uint64(measured.gasRefunded);
        console.log("L1 cold owner transaction gas", total);
        require(ok && abi.decode(result, (bool)), "owner transaction failed");
        require(total * 11 <= 5_000_000 * 10, "L1 baseline lacks ten percent margin");
    }

    function testRejectsCorruptedDeposits() public {
        MainnetHarness upgrade = new MainnetHarness();
        Vm.AccountAccess[] memory accesses = upgrade.depositAccesses();
        bytes[] memory decoded = upgrade.checkDeposits(accesses);
        require(decoded.length == 13, "valid deposits rejected");
        bytes memory original = accesses[0].data;
        bytes memory args = new bytes(original.length - 4);
        for (uint256 i; i < args.length; i++) {
            args[i] = original[i + 4];
        }
        (address to, uint256 value, uint64 gasLimit, bool creation, bytes memory data) =
            abi.decode(args, (address, uint256, uint64, bool, bytes));
        for (uint256 field; field < 5; field++) {
            accesses[0].data = abi.encodeWithSelector(
                bytes4(original),
                field == 0 ? address(1) : to,
                field == 1 ? uint256(1) : value,
                field == 2 ? gasLimit + 1 : gasLimit,
                field == 3 ? true : creation,
                field == 4 ? bytes("corrupt") : data
            );
            string[5] memory errors = [
                string("deposit target mismatch"),
                "deposit value mismatch",
                "deposit gas limit mismatch",
                "deposit creates contract",
                "deposit data mismatch"
            ];
            vm.expectRevert(bytes(errors[field]));
            upgrade.checkDeposits(accesses);
        }
        accesses[0].data = original;
        (accesses[0], accesses[1]) = (accesses[1], accesses[0]);
        vm.expectRevert(bytes("deposit data mismatch"));
        upgrade.checkDeposits(accesses);
    }

    function testRejectsInstalledBaseTime() public {
        MainnetHarness upgrade = new MainnetHarness();
        vm.selectFork(upgrade.l2ForkId());
        vm.store(
            0x4200000000000000000000000000000000000030,
            0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,
            bytes32(uint256(1))
        );
        vm.expectRevert(bytes("BaseTime already installed"));
        upgrade.replay();
    }

    function testRejectsWrongBaseTimeAdmin() public {
        MainnetHarness upgrade = new MainnetHarness();
        vm.selectFork(upgrade.l2ForkId());
        vm.store(
            0x4200000000000000000000000000000000000030,
            0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
            bytes32(uint256(1))
        );
        vm.expectRevert(bytes("BaseTime admin mismatch"));
        upgrade.replay();
    }

    function testLiveRecordsSurviveUpgrade() public {
        MainnetHarness upgrade = _upgradeL2();
        // RelayedMessage at Base block 52953341.
        bytes32 message = 0xad180bec559e0c1f2bad3a30a85216dff3d2753ec11f0bc44613805f5a8a511d;
        // Attested at Base block 52953222.
        bytes32 uid = 0x3ce6ded82196362b8f066060a366c7b058d9b0ad2891cc6f1154fa67e5ef672a;
        bytes32 schema = 0xbde38ceef862b0ec323601a60bda75ffad3b71a8273c9f70f1074cf8c9da15f0;
        // OptimismMintableERC721Created at Base block 40918414.
        address token = 0x2648349b67C3ffDed6410Bd68CeB9Afbe05Dce24;
        // MessagePassed at Base block 52952800.
        bytes32 withdrawal = 0x2e9ae2f6d4e928a6d4e7a282e028fe34b6f14ecfc3cc8509460f30676dea447f;
        address[6] memory targets = [proxies[9], proxies[8], proxies[7], proxies[5], proxies[0], proxies[0]];
        bytes[6] memory reads = [
            abi.encodeWithSignature("successfulMessages(bytes32)", message),
            abi.encodeWithSignature("getAttestation(bytes32)", uid),
            abi.encodeWithSignature("getSchema(bytes32)", schema),
            abi.encodeWithSignature("isOptimismMintableERC721(address)", token),
            abi.encodeWithSignature("sentMessages(bytes32)", withdrawal),
            abi.encodeWithSignature("messageNonce()")
        ];
        bytes32 domainBefore = keccak256(_read(proxies[8], abi.encodeWithSignature("getDomainSeparator()")));
        PreservedState memory state;
        for (uint256 i; i < 9; i++) {
            state.blockAttributes[i] = vm.load(proxies[1], bytes32(i));
        }
        for (uint256 i = 1; i <= 206; i++) {
            state.messengerState[i - 1] = vm.load(proxies[9], bytes32(i));
        }
        // A synthetic delegated nonce also pins the inherited EIP-712 mapping's storage location.
        vm.store(proxies[8], keccak256(abi.encode(address(0xabcd), uint256(0))), bytes32(uint256(17)));
        state.easNonce = _read(proxies[8], abi.encodeWithSignature("getNonce(address)", address(0xabcd)));
        bytes[6] memory beforeReads;
        for (uint256 i; i < 6; i++) {
            beforeReads[i] = _read(targets[i], reads[i]);
            require(keccak256(beforeReads[i]) != keccak256(abi.encode(uint256(0))), "live record missing");
        }
        uint256[4] memory balances;
        bytes32[4] memory totals;
        for (uint256 i; i < 4; i++) {
            address vault = i == 3 ? proxies[6] : proxies[i + 2];
            balances[i] = vault.balance;
            totals[i] = vm.load(vault, bytes32(0));
        }
        // No nonzero L2 deposits entry was identified in the sampled withdrawal events.
        bytes32 depositSlot = keccak256(abi.encode(address(0x5678), keccak256(abi.encode(address(0x1234), uint256(2)))));
        vm.store(proxies[10], depositSlot, bytes32(uint256(123)));
        bytes memory escrowRead = abi.encodeWithSignature("deposits(address,address)", address(0x1234), address(0x5678));
        require(abi.decode(_read(proxies[10], escrowRead), (uint256)) == 123, "legacy escrow fixture inaccessible");
        upgrade.replay();
        for (uint256 i; i < 6; i++) {
            require(keccak256(_read(targets[i], reads[i])) == keccak256(beforeReads[i]), "live record changed");
        }
        for (uint256 i; i < 4; i++) {
            address vault = i == 3 ? proxies[6] : proxies[i + 2];
            require(vault.balance == balances[i] && vm.load(vault, bytes32(0)) == totals[i], "vault accounting changed");
        }
        require(
            abi.decode(_read(proxies[10], escrowRead), (uint256)) == 123, "bridge escrow inaccessible after upgrade"
        );
        for (uint256 i; i < 9; i++) {
            require(vm.load(proxies[1], bytes32(i)) == state.blockAttributes[i], "L1Block attributes changed");
        }
        for (uint256 i = 1; i <= 206; i++) {
            require(vm.load(proxies[9], bytes32(i)) == state.messengerState[i - 1], "messenger legacy state changed");
        }
        require(
            keccak256(_read(proxies[8], abi.encodeWithSignature("getNonce(address)", address(0xabcd))))
                == keccak256(state.easNonce),
            "delegated nonce changed"
        );
        require(
            keccak256(_read(proxies[8], abi.encodeWithSignature("getDomainSeparator()"))) != domainBefore,
            "EAS delegated signature domain not upgraded"
        );
    }

    function testRevertingInitializersRollBack() public {
        vm.selectFork(l2);
        address bad = address(new RevertingInitializer());
        address aliasOwner = 0x8cC51c3008b3f03Fe483B28B8Db90e19cF076a6d;
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        for (uint256 i; i < 13; i++) {
            if (i < 2 || i == 5 || i == 7 || i == 8) continue;
            bytes32 oldImpl = vm.load(proxies[i], implSlot);
            bytes32 initializerSlot = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
            bytes32 oldFlags = vm.load(proxies[i], initializerSlot);
            bytes32[5] memory slots;
            for (uint256 j; j < 5; j++) {
                slots[j] = vm.load(proxies[i], bytes32(j));
            }
            bytes memory init = i >= 9
                ? abi.encodeWithSignature("initialize(address)", address(1))
                : abi.encodeWithSignature("initialize(address,uint256,uint8)", address(1), uint256(1), uint8(1));
            address target = i >= 9 ? vm.envAddress("LEGACY_MIGRATOR") : bad;
            bytes memory data = i >= 9 ? abi.encodeWithSignature("migrate(address,bytes)", bad, init) : init;
            vm.expectCall(bad, init);
            vm.prank(aliasOwner);
            (bool ok, bytes memory reason) =
                ADMIN.call(abi.encodeWithSignature("upgradeAndCall(address,address,bytes)", proxies[i], target, data));
            require(!ok, "failed initializer accepted");
            require(
                keccak256(reason)
                    == keccak256(
                        abi.encodeWithSignature(
                            "Error(string)", "Proxy: delegatecall to new implementation contract failed"
                        )
                    ),
                "upgrade failed before reaching initializer"
            );
            require(vm.load(proxies[i], implSlot) == oldImpl, "failed init changed implementation");
            require(vm.load(proxies[i], initializerSlot) == oldFlags, "failed init changed initializer flags");
            for (uint256 j; j < 5; j++) {
                require(vm.load(proxies[i], bytes32(j)) == slots[j], "failed init changed storage");
            }
        }
    }

    function testDirectMigratorCallReverts() public {
        (bool ok, bytes memory reason) = vm.envAddress("LEGACY_MIGRATOR")
            .call(abi.encodeWithSignature("migrate(address,bytes)", implementations[9], bytes("")));
        require(
            !ok && keccak256(reason) == keccak256(abi.encodeWithSignature("Error(string)", "delegatecall only")),
            "direct migrator call accepted"
        );
    }

    function testBridgeMintBurnAndETHWithdrawal() public {
        MainnetHarness upgrade = _upgradeL2();
        upgrade.replay();
        (bool created, bytes memory result) = proxies[11].call(
            abi.encodeWithSignature(
                "createOptimismMintableERC20(address,string,string)", address(0x1234), "Migration token", "MIG"
            )
        );
        require(created, "token creation failed");
        address token = abi.decode(result, (address));
        require(
            abi.decode(_read(proxies[11], abi.encodeWithSignature("deployments(address)", token)), (address))
                == address(0x1234),
            "new token deployment not tracked"
        );
        bytes memory mint = abi.encodeWithSignature(
            "finalizeBridgeERC20(address,address,address,address,uint256,bytes)",
            token,
            address(0x1234),
            address(0x5678),
            address(this),
            uint256(100),
            bytes("")
        );
        vm.prank(
            address(
                uint160(vm.envAddress("L1_CROSS_DOMAIN_MESSENGER"))
                    + uint160(0x1111000000000000000000000000000000001111)
            )
        );
        (bool relayed,) = proxies[9].call(
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                (uint256(1) << 240) | uint256(987654321),
                vm.envAddress("L1_STANDARD_BRIDGE"),
                proxies[10],
                uint256(0),
                uint256(200000),
                mint
            )
        );
        require(relayed, "deposit relay reverted");
        require(
            abi.decode(_read(token, abi.encodeWithSignature("balanceOf(address)", address(this))), (uint256)) == 100,
            "relay did not mint"
        );
        (bool burned,) = proxies[10].call(
            abi.encodeWithSignature(
                "bridgeERC20To(address,address,address,uint256,uint32,bytes)",
                token,
                address(0x1234),
                address(0x5678),
                uint256(40),
                uint32(100000),
                bytes("")
            )
        );
        require(burned, "bridge burn reverted");
        require(
            abi.decode(_read(token, abi.encodeWithSignature("balanceOf(address)", address(this))), (uint256)) == 60,
            "burn amount wrong"
        );
        uint256 nonce = abi.decode(_read(proxies[0], abi.encodeWithSignature("messageNonce()")), (uint256));
        uint256 balance = proxies[0].balance;
        vm.deal(address(this), 1 ether);
        (bool withdrawn,) = proxies[10].call{value: 1 ether}(
            abi.encodeWithSignature("bridgeETHTo(address,uint32,bytes)", address(0x5678), uint32(100000), bytes(""))
        );
        require(withdrawn, "ETH bridge reverted");
        require(proxies[0].balance == balance + 1 ether, "withdrawal value not in message passer");
        require(
            abi.decode(_read(proxies[0], abi.encodeWithSignature("messageNonce()")), (uint256)) == nonce + 1,
            "withdrawal not enqueued"
        );
    }

    function testPortalFeeSensitivity() public {
        address portal = vm.envAddress("OPTIMISM_PORTAL");
        vm.store(portal, bytes32(uint256(1)), bytes32(uint256(2 gwei) | (uint256(block.number) << 192)));
        MainnetHarness upgrade = new MainnetHarness();
        upgrade.setUp();
        vm.prank(vm.envAddress("CB_MULTISIG"));
        upgrade.simulateForTest();
    }

    function testRejectsPortalFeesWithoutGasHeadroom() public {
        vm.fee(0);
        address portal = vm.envAddress("OPTIMISM_PORTAL");
        vm.store(portal, bytes32(uint256(1)), bytes32(uint256(3 gwei) | (uint256(block.number) << 192)));
        MainnetHarness upgrade = new MainnetHarness();
        vm.expectRevert(bytes("portal fees exceed L1 gas budget"));
        upgrade.setUp();
    }

    function testPortalGasBudgetUsesL1Basefee() public {
        vm.fee(3 gwei);
        address portal = vm.envAddress("OPTIMISM_PORTAL");
        vm.store(portal, bytes32(uint256(1)), bytes32(uint256(6 gwei) | (uint256(block.number) << 192)));
        MainnetHarness upgrade = new MainnetHarness();
        upgrade.setUp();
    }

    function testRejectsPortalFeeIncreaseAfterFullBlock() public {
        vm.fee(1 gwei);
        address portal = vm.envAddress("OPTIMISM_PORTAL");
        vm.store(
            portal,
            bytes32(uint256(1)),
            bytes32(uint256(2 gwei) | (uint256(20_000_000) << 128) | (uint256(block.number - 1) << 192))
        );
        MainnetHarness upgrade = new MainnetHarness();
        vm.expectRevert(bytes("portal fees exceed L1 gas budget"));
        upgrade.setUp();
    }

    function testRejectsChangedSafeThreshold() public {
        MainnetHarness upgrade = new MainnetHarness();
        vm.mockCall(
            vm.envAddress("BASE_SECURITY_COUNCIL"), abi.encodeWithSignature("getThreshold()"), abi.encode(uint256(1))
        );
        vm.expectRevert(bytes("Safe threshold changed"));
        upgrade.setUp();
    }

    function testMainnetSignerSimulation() public {
        MainnetHarness upgrade = new MainnetHarness();
        upgrade.setUp();
        vm.prank(vm.envAddress("CB_MULTISIG"));
        upgrade.simulateForTest();
    }
}
