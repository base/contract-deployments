// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";

import {MultisigScript, Enum} from "@base-contracts/scripts/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/scripts/universal/Simulation.sol";
import {TEEProverRegistry} from "@base-contracts/src/L1/proofs/tee/TEEProverRegistry.sol";
import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";
import {CertManager} from "nitro-validator/src/CertManager.sol";
import {NitroValidator} from "nitro-validator/src/NitroValidator.sol";

interface IProxyAdmin {
    function owner() external view returns (address);
    function upgrade(address proxy, address implementation) external;
}

interface ILegacyTEEProverRegistry {
    function NITRO_VERIFIER() external view returns (address);
    function DISPUTE_GAME_FACTORY() external view returns (address);
    function version() external pure returns (string memory);
}

interface ITEEProverRegistryState {
    function owner() external view returns (address);
    function manager() external view returns (address);
    function gameType() external view returns (GameType);
    function isRegisteredSigner(address signer) external view returns (bool);
    function signerImageHash(address signer) external view returns (bytes32);
    function isValidSigner(address signer) external view returns (bool);
    function isValidProposer(address proposer) external view returns (bool);
    function getRegisteredSigners() external view returns (address[] memory);
    function getExpectedImageHash() external view returns (bytes32);
}

interface ITEEVerifier {
    function TEE_PROVER_REGISTRY() external view returns (address);
}

/// @notice Upgrades or rolls back the TEEProverRegistry implementation.
/// @dev Rollback validation overrides the implementation slot to model post-upgrade state.
contract SetTEEProverRegistryImpl is MultisigScript {
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    address internal immutable ownerSafe;
    address internal immutable proxyAdmin;
    address internal immutable teeProverRegistryProxy;
    address internal immutable teeVerifier;
    address internal immutable disputeGameFactoryProxy;
    address internal immutable proposer;
    address internal immutable challenger;
    address internal immutable certManagerOwner;
    address internal immutable certManagerRevoker;
    address internal immutable oldTeeProverRegistryImpl;
    address internal immutable newTeeProverRegistryImpl;
    address internal immutable oldNitroVerifier;
    address internal immutable newP384Verifier;
    address internal immutable newCertManager;
    address internal immutable newNitroValidator;
    address internal immutable targetTeeProverRegistryImpl;
    address internal immutable assumedCurrentTeeProverRegistryImpl;
    bytes32 internal immutable registryStateDigest;

    constructor() {
        ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
        proxyAdmin = vm.envAddress("L1_PROXY_ADMIN");
        teeProverRegistryProxy = vm.envAddress("TEE_PROVER_REGISTRY_PROXY");
        teeVerifier = vm.envAddress("TEE_VERIFIER");
        disputeGameFactoryProxy = vm.envAddress("DISPUTE_GAME_FACTORY_PROXY");
        proposer = vm.envAddress("PROPOSER");
        challenger = vm.envAddress("CHALLENGER");
        certManagerOwner = vm.envAddress("CERT_MANAGER_OWNER");
        certManagerRevoker = vm.envAddress("CERT_MANAGER_REVOKER");
        oldTeeProverRegistryImpl = vm.envAddress("OLD_TEE_PROVER_REGISTRY_IMPL");
        newTeeProverRegistryImpl = vm.envAddress("NEW_TEE_PROVER_REGISTRY_IMPL");
        oldNitroVerifier = vm.envAddress("OLD_NITRO_VERIFIER");
        newP384Verifier = vm.envAddress("NEW_P384_VERIFIER");
        newCertManager = vm.envAddress("NEW_CERT_MANAGER");
        newNitroValidator = vm.envAddress("NEW_NITRO_VALIDATOR");
        targetTeeProverRegistryImpl = vm.envAddress("TARGET_TEE_PROVER_REGISTRY_IMPL");
        assumedCurrentTeeProverRegistryImpl = vm.envAddress("ASSUMED_CURRENT_TEE_PROVER_REGISTRY_IMPL");
        registryStateDigest = _registryStateDigest();
    }

    function setUp() public view {
        _preCheck();
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: proxyAdmin,
            data: abi.encodeCall(IProxyAdmin.upgrade, (teeProverRegistryProxy, targetTeeProverRegistryImpl)),
            value: 0
        });
        return calls;
    }

    function _simulationOverrides() internal view override returns (Simulation.StateOverride[] memory) {
        if (_implementation() == assumedCurrentTeeProverRegistryImpl) {
            return new Simulation.StateOverride[](0);
        }

        Simulation.StorageOverride[] memory storageOverrides = new Simulation.StorageOverride[](1);
        storageOverrides[0] = Simulation.StorageOverride({
            key: IMPLEMENTATION_SLOT, value: bytes32(uint256(uint160(assumedCurrentTeeProverRegistryImpl)))
        });

        Simulation.StateOverride[] memory stateOverrides = new Simulation.StateOverride[](1);
        stateOverrides[0] =
            Simulation.StateOverride({contractAddress: teeProverRegistryProxy, overrides: storageOverrides});
        return stateOverrides;
    }

    function _preCheck() internal view {
        require(IProxyAdmin(proxyAdmin).owner() == ownerSafe, "proxy admin owner mismatch");
        require(
            ITEEVerifier(teeVerifier).TEE_PROVER_REGISTRY() == teeProverRegistryProxy, "tee verifier registry mismatch"
        );
        require(
            (_implementation() == assumedCurrentTeeProverRegistryImpl)
                || (_implementation() == targetTeeProverRegistryImpl),
            "unexpected live implementation"
        );
        require(
            (targetTeeProverRegistryImpl == newTeeProverRegistryImpl
                    && assumedCurrentTeeProverRegistryImpl == oldTeeProverRegistryImpl)
                || (targetTeeProverRegistryImpl == oldTeeProverRegistryImpl
                    && assumedCurrentTeeProverRegistryImpl == newTeeProverRegistryImpl),
            "invalid implementation transition"
        );

        ILegacyTEEProverRegistry oldRegistry = ILegacyTEEProverRegistry(oldTeeProverRegistryImpl);
        TEEProverRegistry newRegistry = TEEProverRegistry(newTeeProverRegistryImpl);
        require(oldRegistry.DISPUTE_GAME_FACTORY() == disputeGameFactoryProxy, "old registry factory mismatch");
        require(address(newRegistry.DISPUTE_GAME_FACTORY()) == disputeGameFactoryProxy, "new registry factory mismatch");
        require(oldRegistry.NITRO_VERIFIER() == oldNitroVerifier, "old registry nitro mismatch");
        require(address(newRegistry.NITRO_VALIDATOR()) == newNitroValidator, "new registry nitro mismatch");
        require(keccak256(bytes(oldRegistry.version())) == keccak256(bytes("0.5.0")), "old version mismatch");
        require(keccak256(bytes(newRegistry.version())) == keccak256(bytes("0.6.1")), "new version mismatch");

        _assertNitroStack();
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        require(_implementation() == targetTeeProverRegistryImpl, "tee registry implementation mismatch");
        require(_registryStateDigest() == registryStateDigest, "tee registry state changed");
        require(
            ITEEVerifier(teeVerifier).TEE_PROVER_REGISTRY() == teeProverRegistryProxy, "tee verifier registry changed"
        );

        if (targetTeeProverRegistryImpl == newTeeProverRegistryImpl) {
            TEEProverRegistry registry = TEEProverRegistry(teeProverRegistryProxy);
            require(address(registry.NITRO_VALIDATOR()) == newNitroValidator, "proxy nitro validator mismatch");
            require(keccak256(bytes(registry.version())) == keccak256(bytes("0.6.1")), "proxy version mismatch");
            _assertNitroStack();
        } else {
            ILegacyTEEProverRegistry registry = ILegacyTEEProverRegistry(teeProverRegistryProxy);
            require(registry.NITRO_VERIFIER() == oldNitroVerifier, "proxy legacy nitro mismatch");
            require(keccak256(bytes(registry.version())) == keccak256(bytes("0.5.0")), "proxy version mismatch");
        }
    }

    function _assertNitroStack() internal view {
        NitroValidator validator = NitroValidator(newNitroValidator);
        CertManager manager = CertManager(address(validator.certManager()));
        require(address(validator.certManager()) == newCertManager, "cert manager mismatch");
        require(address(validator.p384Verifier()) == newP384Verifier, "validator p384 mismatch");
        require(address(manager.p384Verifier()) == newP384Verifier, "cert manager p384 mismatch");
        require(manager.owner() == certManagerOwner, "cert manager owner mismatch");
        require(manager.revoker() == certManagerRevoker, "cert manager revoker mismatch");
        require(manager.verified(manager.ROOT_CA_CERT_HASH()).length != 0, "root certificate not cached");
    }

    function _registryStateDigest() internal view returns (bytes32) {
        ITEEProverRegistryState registry = ITEEProverRegistryState(teeProverRegistryProxy);
        address[] memory signers = registry.getRegisteredSigners();
        bytes32[] memory imageHashes = new bytes32[](signers.length);
        bool[] memory validSigners = new bool[](signers.length);
        for (uint256 i = 0; i < signers.length; i++) {
            require(registry.isRegisteredSigner(signers[i]), "enumerated signer not registered");
            imageHashes[i] = registry.signerImageHash(signers[i]);
            validSigners[i] = registry.isValidSigner(signers[i]);
        }

        return keccak256(
            abi.encode(
                registry.owner(),
                registry.manager(),
                registry.gameType(),
                registry.isValidProposer(proposer),
                registry.isValidProposer(challenger),
                registry.getExpectedImageHash(),
                signers,
                imageHashes,
                validSigners
            )
        );
    }

    function _implementation() internal view returns (address) {
        return address(uint160(uint256(vm.load(teeProverRegistryProxy, IMPLEMENTATION_SLOT))));
    }

    function _ownerSafe() internal view override returns (address) {
        return ownerSafe;
    }
}
