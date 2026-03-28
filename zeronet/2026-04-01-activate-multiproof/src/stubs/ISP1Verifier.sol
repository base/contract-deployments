// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Stub of ISP1Verifier with a relaxed pragma (^0.8.0 instead of ^0.8.20)
///         so NitroEnclaveVerifier can compile alongside =0.8.15 contracts.
///         Content is identical to lib/sp1-contracts/contracts/src/ISP1Verifier.sol.

interface ISP1Verifier {
    function verifyProof(bytes32 programVKey, bytes calldata publicValues, bytes calldata proofBytes) external view;
}

interface ISP1VerifierWithHash is ISP1Verifier {
    function VERIFIER_HASH() external pure returns (bytes32);
}
