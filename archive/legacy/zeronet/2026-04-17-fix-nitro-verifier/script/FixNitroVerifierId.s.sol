// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";

import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {ZkCoProcessorConfig, ZkCoProcessorType} from "interfaces/multiproof/tee/INitroEnclaveVerifier.sol";
import {NitroEnclaveVerifier} from "@base-contracts/src/multiproof/tee/NitroEnclaveVerifier.sol";

contract FixNitroVerifierId is MultisigScript {
    address internal nitroOwnerEnv;
    address internal nitroEnclaveVerifierEnv;
    bytes32 internal currentNitroZkVerifierIdEnv;
    bytes32 internal newNitroZkVerifierIdEnv;

    address internal currentProofSubmitter;
    address internal currentRevoker;
    uint64 internal currentMaxTimeDiff;
    bytes32 internal currentRootCert;
    bytes32 internal currentAggregatorId;
    address internal currentRouter;
    bytes32 internal currentVerifierProofId;

    function setUp() public {
        nitroOwnerEnv = vm.envAddress("TEE_PROVER_REGISTRY_OWNER");
        nitroEnclaveVerifierEnv = vm.envAddress("NITRO_ENCLAVE_VERIFIER");
        currentNitroZkVerifierIdEnv = vm.envBytes32("CURRENT_NITRO_ZK_VERIFIER_ID");
        newNitroZkVerifierIdEnv = vm.envBytes32("NITRO_ZK_VERIFIER_ID");

        require(currentNitroZkVerifierIdEnv != newNitroZkVerifierIdEnv, "verifier id already target");

        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifierEnv);
        require(nev.owner() == nitroOwnerEnv, "nitro owner mismatch");

        currentProofSubmitter = nev.proofSubmitter();
        currentRevoker = nev.revoker();
        currentMaxTimeDiff = nev.maxTimeDiff();
        currentRootCert = nev.rootCert();
        currentVerifierProofId = nev.getVerifierProofId(ZkCoProcessorType.RiscZero);

        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);
        require(cfg.verifierId == currentNitroZkVerifierIdEnv, "unexpected current verifier id");

        currentAggregatorId = cfg.aggregatorId;
        currentRouter = cfg.zkVerifier;
    }

    function _buildCalls() internal view override returns (Call[] memory calls) {
        calls = new Call[](1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: nitroEnclaveVerifierEnv,
            data: abi.encodeCall(
                NitroEnclaveVerifier.updateVerifierId,
                (ZkCoProcessorType.RiscZero, newNitroZkVerifierIdEnv, currentVerifierProofId)
            ),
            value: 0
        });
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        NitroEnclaveVerifier nev = NitroEnclaveVerifier(nitroEnclaveVerifierEnv);
        ZkCoProcessorConfig memory cfg = nev.getZkConfig(ZkCoProcessorType.RiscZero);

        require(nev.owner() == nitroOwnerEnv, "nitro owner changed");
        require(nev.proofSubmitter() == currentProofSubmitter, "nitro proof submitter changed");
        require(nev.revoker() == currentRevoker, "nitro revoker changed");
        require(nev.maxTimeDiff() == currentMaxTimeDiff, "nitro max time diff changed");
        require(nev.rootCert() == currentRootCert, "nitro root cert changed");
        require(cfg.verifierId == newNitroZkVerifierIdEnv, "nitro verifier id mismatch");
        require(cfg.aggregatorId == currentAggregatorId, "nitro aggregator id changed");
        require(cfg.zkVerifier == currentRouter, "nitro router changed");
        require(
            nev.getVerifierProofId(ZkCoProcessorType.RiscZero) == currentVerifierProofId,
            "nitro verifier proof id changed"
        );
    }

    function _ownerSafe() internal view override returns (address) {
        return nitroOwnerEnv;
    }
}
