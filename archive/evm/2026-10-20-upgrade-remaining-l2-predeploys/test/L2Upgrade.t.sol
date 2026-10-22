// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {L2Upgrade} from "../script/L2Upgrade.sol";
import {LegacyMigrator} from "../script/LegacyMigrator.sol";

import {L2StandardBridge} from "@base-contracts/src/L2/L2StandardBridge.sol";

abstract contract L2UpgradeTest is L2Upgrade {
    address internal localMigrator;

    function _migrator() internal view override returns (address) {
        return localMigrator;
    }

    struct AttestationData {
        address recipient;
        uint64 expirationTime;
        bool revocable;
        bytes32 refUID;
        bytes data;
        uint256 value;
    }

    struct AttestationRequest {
        bytes32 schema;
        AttestationData data;
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("L2_RPC_URL"));
        localMigrator = address(new LegacyMigrator());
    }

    function _deploy(string memory artifact, bytes memory args) internal returns (address deployed) {
        bytes memory code = abi.encodePacked(vm.getCode(artifact), args);
        assembly { deployed := create(0, add(code, 32), mload(code)) }
        require(deployed != address(0), "local deployment failed");
    }

    function _implementations() internal returns (address[8] memory) {
        return [
            _deploy(
                "OptimismMintableERC721Factory.sol:OptimismMintableERC721Factory",
                abi.encode(factoryBridge, remoteChainId)
            ),
            _deploy("OperatorFeeVault.sol:OperatorFeeVault", ""),
            _deploy("SchemaRegistry.sol:SchemaRegistry", ""),
            _deploy("EAS.sol:EAS", ""),
            _deploy("L2CrossDomainMessenger.sol:L2CrossDomainMessenger", ""),
            _deploy("L2StandardBridge.sol:L2StandardBridge", ""),
            _deploy("OptimismMintableERC20Factory.sol:OptimismMintableERC20Factory", ""),
            _deploy("L2ERC721Bridge.sol:L2ERC721Bridge", "")
        ];
    }

    function _call(address target, bytes memory data) internal returns (bytes memory result) {
        bool ok;
        (ok, result) = target.call(data);
        require(ok, "fixture call failed");
    }

    function _uintWithArgs(address target, bytes memory data) internal returns (uint256) {
        return abi.decode(_call(target, data), (uint256));
    }

    function _assertERC20Bridge() internal {
        address remoteToken = address(0x1234);
        address token = abi.decode(
            _call(
                ERC20_FACTORY,
                abi.encodeWithSignature(
                    "createOptimismMintableERC20(address,string,string)", remoteToken, "Migration token", "MIG"
                )
            ),
            (address)
        );
        require(_uint(token, "BRIDGE()") == uint160(BRIDGE), "token bridge mismatch");
        vm.store(MESSENGER, bytes32(uint256(204)), bytes32(uint256(uint160(l1Bridge))));
        vm.prank(MESSENGER);
        L2StandardBridge(payable(BRIDGE))
            .finalizeBridgeERC20(token, remoteToken, address(0x5678), address(this), 100, "");
        vm.store(MESSENGER, bytes32(uint256(204)), bytes32(uint256(0xdead)));
        require(
            _uintWithArgs(token, abi.encodeWithSignature("balanceOf(address)", address(this))) == 100,
            "bridge mint failed"
        );
        _call(
            BRIDGE,
            abi.encodeWithSignature(
                "bridgeERC20To(address,address,address,uint256,uint32,bytes)",
                token,
                remoteToken,
                address(0x5678),
                40,
                uint32(100000),
                bytes("")
            )
        );
        require(
            _uintWithArgs(token, abi.encodeWithSignature("balanceOf(address)", address(this))) == 60,
            "bridge burn failed"
        );
    }

    function testUpgradePreservesConfiguration() public {
        address[8] memory impls = _implementations();
        address token = abi.decode(
            _call(
                FACTORY,
                abi.encodeWithSignature(
                    "createOptimismMintableERC721(address,string,string)", address(0x1234), "Test", "TEST"
                )
            ),
            (address)
        );
        bytes memory factoryRead = abi.encodeWithSignature("isOptimismMintableERC721(address)", token);
        require(abi.decode(_call(FACTORY, factoryRead), (bool)), "factory fixture missing");
        vm.deal(VAULT, 1 ether);
        _call(VAULT, abi.encodeWithSignature("withdraw()"));
        require(_uint(VAULT, "totalProcessed()") != 0, "vault fixture missing");
        bytes32 schema = abi.decode(
            _call(
                REGISTRY, abi.encodeWithSignature("register(string,address,bool)", "uint256 value", address(0), true)
            ),
            (bytes32)
        );
        AttestationRequest memory request =
            AttestationRequest(schema, AttestationData(address(this), 0, true, bytes32(0), abi.encode(uint256(42)), 0));
        bytes32 uid = abi.decode(
            _call(
                EAS_PROXY,
                abi.encodeWithSignature("attest((bytes32,(address,uint64,bool,bytes32,bytes,uint256)))", request)
            ),
            (bytes32)
        );
        bytes memory schemaRead = abi.encodeWithSignature("getSchema(bytes32)", schema);
        bytes memory attestationRead = abi.encodeWithSignature("getAttestation(bytes32)", uid);
        bytes32 beforeSchema = keccak256(_call(REGISTRY, schemaRead));
        bytes32 beforeAttestation = keccak256(_call(EAS_PROXY, attestationRead));
        bytes32 messageHash = keccak256("pre-existing successful message");
        bytes32 successfulSlot = keccak256(abi.encode(messageHash, uint256(203)));
        bytes32 depositsSlot =
            keccak256(abi.encode(address(0x5678), keccak256(abi.encode(address(0x1234), uint256(2)))));
        // Synthetic entries avoid relying on an undocumented live message hash or token pair.
        vm.store(MESSENGER, successfulSlot, bytes32(uint256(1)));
        vm.store(BRIDGE, depositsSlot, bytes32(uint256(123)));
        require(
            _uintWithArgs(MESSENGER, abi.encodeWithSignature("successfulMessages(bytes32)", messageHash)) == 1,
            "message fixture missing"
        );
        require(
            _uintWithArgs(
                    BRIDGE, abi.encodeWithSignature("deposits(address,address)", address(0x1234), address(0x5678))
                ) == 123,
            "deposits fixture missing"
        );
        _replay(impls);
        require(
            _uintWithArgs(MESSENGER, abi.encodeWithSignature("successfulMessages(bytes32)", messageHash)) == 1,
            "successful message lost"
        );
        require(
            _uintWithArgs(
                    BRIDGE, abi.encodeWithSignature("deposits(address,address)", address(0x1234), address(0x5678))
                ) == 123,
            "deposits lost"
        );
        _assertERC20Bridge();
        require(keccak256(_call(REGISTRY, schemaRead)) == beforeSchema, "schema storage changed");
        require(keccak256(_call(EAS_PROXY, attestationRead)) == beforeAttestation, "attestation storage changed");
        require(abi.decode(_call(FACTORY, factoryRead), (bool)), "factory registration lost");
    }
}
