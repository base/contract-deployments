// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {L2Upgrade} from "../script/L2Upgrade.sol";
import {IProxyAdmin} from "interfaces/universal/IProxyAdmin.sol";
import {AddressAliasHelper} from "src/vendor/AddressAliasHelper.sol";

import {L2CrossDomainMessenger} from "@base-contracts/src/L2/L2CrossDomainMessenger.sol";
import {L2StandardBridge} from "@base-contracts/src/L2/L2StandardBridge.sol";
import {L2ERC721Bridge} from "@base-contracts/src/L2/L2ERC721Bridge.sol";
import {OptimismMintableERC20Factory} from "@base-contracts/src/universal/OptimismMintableERC20Factory.sol";

abstract contract L2UpgradeTest is L2Upgrade {
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
    }

    function _deploy(string memory artifact, bytes memory args) internal returns (address deployed) {
        bytes memory code = abi.encodePacked(vm.getCode(artifact), args);
        assembly { deployed := create(0, add(code, 32), mload(code)) }
        require(deployed != address(0), "local deployment failed");
    }

    function _implementations() internal returns (address[4] memory) {
        return [
            _deploy(
                "OptimismMintableERC721Factory.sol:OptimismMintableERC721Factory",
                abi.encode(factoryBridge, remoteChainId)
            ),
            _deploy("OperatorFeeVault.sol:OperatorFeeVault", ""),
            _deploy("SchemaRegistry.sol:SchemaRegistry", ""),
            _deploy("EAS.sol:EAS", "")
        ];
    }

    function testExcludedMigrationsRejectExistingInitializerVersion() public {
        address[4] memory proxies = [
            address(0x4200000000000000000000000000000000000007),
            address(0x4200000000000000000000000000000000000010),
            address(0x4200000000000000000000000000000000000014),
            address(0x4200000000000000000000000000000000000012)
        ];
        address[4] memory implementations = [
            address(new L2CrossDomainMessenger()),
            address(new L2StandardBridge()),
            address(new L2ERC721Bridge()),
            address(new OptimismMintableERC20Factory())
        ];
        address[4] memory counterparts = [
            vm.envAddress("L1_CROSS_DOMAIN_MESSENGER"),
            vm.envAddress("L1_STANDARD_BRIDGE"),
            vm.envAddress("L1_ERC721_BRIDGE"),
            address(0x4200000000000000000000000000000000000010)
        ];
        for (uint256 i; i < 4; i++) {
            uint256 initialSlot = uint256(vm.load(proxies[i], bytes32(0)));
            require(uint8(initialSlot >> (i == 0 ? 160 : 0)) == 2, "legacy initializer changed");
            vm.prank(AddressAliasHelper.applyL1ToL2Alias(ownerSafe));
            IProxyAdmin(ADMIN).upgrade(payable(proxies[i]), implementations[i]);
            vm.expectRevert(bytes("Initializable: contract is already initialized"));
            (bool ok,) = proxies[i].call(abi.encodeWithSignature("initialize(address)", counterparts[i]));
            require(ok, "initialization failed");
            string memory getter =
                i == 0 ? "otherMessenger()" : i == 1 ? "otherBridge()" : i == 2 ? "messenger()" : "bridge()";
            require(_uint(proxies[i], getter) == 0, "expected missing migrated configuration");
        }
    }

    function _call(address target, bytes memory data) internal returns (bytes memory result) {
        bool ok;
        (ok, result) = target.call(data);
        require(ok, "fixture call failed");
    }

    function testUpgradePreservesConfiguration() public {
        address[4] memory impls = _implementations();
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
        _replay(impls);
        require(keccak256(_call(REGISTRY, schemaRead)) == beforeSchema, "schema storage changed");
        require(keccak256(_call(EAS_PROXY, attestationRead)) == beforeAttestation, "attestation storage changed");
        require(abi.decode(_call(FACTORY, factoryRead), (bool)), "factory registration lost");
    }
}
