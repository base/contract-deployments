// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// solhint-disable no-console
import {console} from "lib/forge-std/src/console.sol";
import {IMulticall3} from "lib/forge-std/src/interfaces/IMulticall3.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";

import {IGnosisSafe, Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";
import {Signatures} from "@base-contracts/script/universal/Signatures.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {StateDiff} from "@base-contracts/script/universal/StateDiff.sol";
import {CBMulticall} from "@base-contracts/src/utils/CBMulticall.sol";

/// @title MultisigScript
/// @notice Script builder for Forge scripts that require signatures from Safes. Supports both non-nested
///         Safes, as well as nested Safes of arbitrary depth (Safes where the signers are other Safes).
///
/// 1. Non-nested example:
///
/// Setup:
/// ┌───────┐┌───────┐
/// │Signer1││Signer2│
/// └┬──────┘└┬──────┘
/// ┌▽────────▽┐
/// │Multisig  │
/// └┬─────────┘
/// ┌▽─────────┐
/// │ProxyAdmin│
/// └──────────┘
///
/// Sequence:
/// ┌───────┐┌───────┐┌───────────┐┌──────────────┐
/// │Signer1││Signer2││Facilitator││MultisigScript│
/// └───┬───┘└───┬───┘└─────┬─────┘└───────┬──────┘
///     │        │     sign()              │
///     │─────────────────────────────────>│
///     │      <sig1>       │              │
///     │──────────────────>│              │
///     │        │         sign()          │
///     │        │────────────────────────>│
///     │        │  <sig2>  │              │
///     │        │─────────>│              │
///     │        │          │run(sig1,sig2)│
///     │        │          │─────────────>│
///
///
/// 2. Single-layer nested example:
///
/// Setup:
/// ┌───────┐┌───────┐┌───────┐┌───────┐
/// │Signer1││Signer2││Signer3││Signer4│
/// └┬──────┘└┬──────┘└┬──────┘└┬──────┘
/// ┌▽────────▽┐┌──────▽────────▽┐
/// │Safe1     ││Safe2           │
/// └┬─────────┘└┬───────────────┘
/// ┌▽───────────▽┐
/// │Safe3        │
/// └┬────────────┘
/// ┌▽─────────┐
/// │ProxyAdmin│
/// └──────────┘
///
/// Sequence:
/// ┌───────┐┌───────┐┌───────┐┌───────┐┌───────────┐          ┌──────────────┐
/// │Signer1││Signer2││Signer3││Signer4││Facilitator│          │MultisigScript│
/// └───┬───┘└───┬───┘└───┬───┘└───┬───┘└─────┬─────┘          └───────┬──────┘
///     │        │        │       sign(Safe1) │                        │
///     │─────────────────────────────────────────────────────────────>│
///     │        │      <sig1>     │          │                        │
///     │────────────────────────────────────>│                        │
///     │        │        │        │   sign(Safe1)                     │
///     │        │────────────────────────────────────────────────────>│
///     │        │        │  <sig2>│          │                        │
///     │        │───────────────────────────>│                        │
///     │        │        │        │          │approve(Safe1,sig1|sig2)│
///     │        │        │        │          │───────────────────────>│
///     │        │        │        │       sign(Safe2)                 │
///     │        │        │───────────────────────────────────────────>│
///     │        │        │      <sig3>       │                        │
///     │        │        │──────────────────>│                        │
///     │        │        │        │          │ sign(Safe2)            │
///     │        │        │        │──────────────────────────────────>│
///     │        │        │        │  <sig4>  │                        │
///     │        │        │        │─────────>│                        │
///     │        │        │        │          │approve(Safe2,sig3|sig4)│
///     │        │        │        │          │───────────────────────>│
///     │        │        │        │          │         run()          │
///     │        │        │        │          │───────────────────────>│
///
///
/// 3. Multi-layer nested example:
///
/// Setup:
/// ┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐
/// │Signer1││Signer2││Signer3││Signer4││Signer5││Signer6│
/// └┬──────┘└┬──────┘└┬──────┘└┬──────┘└┬──────┘└┬──────┘
/// ┌▽────────▽┐┌──────▽────────▽┐┌──────▽────────▽┐
/// │Safe1     ││Safe2           ││Safe3           │
/// └┬─────────┘└┬───────────────┘└┬───────────────┘
/// ┌▽───────────▽┐                │
/// │Safe4        │                │
/// └┬────────────┘                │
/// ┌▽─────────────────────────────▽┐
/// │Safe5                          │
/// └┬──────────────────────────────┘
/// ┌▽─────────┐
/// │ProxyAdmin│
/// └──────────┘
///
/// Sequence:
/// ┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐┌───────┐┌───────────┐                ┌──────────────┐
/// │Signer1││Signer2││Signer3││Signer4││Signer5││Signer6││Facilitator│                │MultisigScript│
/// └───┬───┘└───┬───┘└───┬───┘└───┬───┘└───┬───┘└───┬───┘└─────┬─────┘                └───────┬──────┘
///     │        │        │        │       sign(Safe1,Safe4)    │                              │
///     │─────────────────────────────────────────────────────────────────────────────────────>│
///     │        │        │      <sig1>     │        │          │                              │
///     │──────────────────────────────────────────────────────>│                              │
///     │        │        │        │        │   sign(Safe1,Safe4)                              │
///     │        │────────────────────────────────────────────────────────────────────────────>│
///     │        │        │        │  <sig2>│        │          │                              │
///     │        │─────────────────────────────────────────────>│                              │
///     │        │        │        │        │        │          │approve(Safe1,Safe4,sig1|sig2)│
///     │        │        │        │        │        │          │─────────────────────────────>│
///     │        │        │        │        │       sign(Safe2,Safe4)                          │
///     │        │        │───────────────────────────────────────────────────────────────────>│
///     │        │        │        │      <sig3>     │          │                              │
///     │        │        │────────────────────────────────────>│                              │
///     │        │        │        │        │        │   sign(Safe2,Safe4)                     │
///     │        │        │        │──────────────────────────────────────────────────────────>│
///     │        │        │        │        │  <sig4>│          │                              │
///     │        │        │        │───────────────────────────>│                              │
///     │        │        │        │        │        │          │approve(Safe2,Safe4,sig3|sig4)│
///     │        │        │        │        │        │          │─────────────────────────────>│
///     │        │        │        │        │        │          │        approve(Safe4)        │
///     │        │        │        │        │        │          │─────────────────────────────>│
///     │        │        │        │        │        │          sign(Safe3)                    │
///     │        │        │        │        │─────────────────────────────────────────────────>│
///     │        │        │        │        │      <sig5>       │                              │
///     │        │        │        │        │──────────────────>│                              │
///     │        │        │        │        │        │          │    sign(Safe3)               │
///     │        │        │        │        │        │────────────────────────────────────────>│
///     │        │        │        │        │        │  <sig6>  │                              │
///     │        │        │        │        │        │─────────>│                              │
///     │        │        │        │        │        │          │   approve(Safe3,sig5|sig6)   │
///     │        │        │        │        │        │          │─────────────────────────────>│
///     │        │        │        │        │        │          │            run()             │
///     │        │        │        │        │        │          │─────────────────────────────>│
abstract contract MultisigScript is Script {
    bytes32 internal constant SAFE_NONCE_SLOT = bytes32(uint256(5));

    address internal constant MULTICALL3_DELEGATECALL_ADDRESS = 0x93dc480940585D9961bfcEab58124fFD3d60f76a;

    address internal multicallAddress;

    /// @dev Event emitted from a `sign()` call containing the data to sign. Used in testing.
    event DataToSign(bytes data);

    //////////////////////////////////////////////////////////////////////////////////////
    ///                               Virtual Functions                                ///
    //////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the safe address to execute the final transaction from
    function _ownerSafe() internal view virtual returns (address);

    /// @notice Creates the calldata for signatures (`sign`), approvals (`approve`), and execution (`run`)
    function _buildCalls() internal view virtual returns (IMulticall3.Call3Value[] memory);

    /// @notice Follow up assertions to ensure that the script ran to completion.
    /// @dev Called after `sign` and `run`, but not `approve`.
    function _postCheck(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual;

    /// @notice Follow up assertions on state and simulation after a `sign` call.
    function _postSign(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /// @notice Follow up assertions on state and simulation after a `approve` call.
    function _postApprove(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    /// @notice Follow up assertions on state and simulation after a `run` call.
    function _postRun(Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) internal virtual {}

    // Tenderly simulations can accept generic state overrides. This hook enables this functionality.
    // By default, an empty (no-op) override is returned.
    function _simulationOverrides() internal view virtual returns (Simulation.StateOverride[] memory overrides_) {}

    /// @notice If set to true, the executed aggregate call runs through the custom `CBMulticall` contract
    ///         as a `DELEGATECALL` for each individual call.
    /// @dev    In delegatecall mode:
    ///         - The multisig inherits the multicall logic and executes each target in its own context
    ///           (e.g. for Optimism's OPCM-style flows).
    ///         - The `value` field of each `IMulticall3.Call3Value` returned by `_buildCalls` MUST be zero.
    ///           Per-call value routing is not supported; any ETH attached to the Safe transaction is shared
    ///           across all calls according to the delegatee's logic.
    function _useDelegateCall() internal view virtual returns (bool) {
        return false;
    }

    constructor() {
        bool useCbMulticall;
        try vm.envBool("USE_MULTICALL3_DELEGATECALL_ADDRESS") {
            useCbMulticall = vm.envBool("USE_MULTICALL3_DELEGATECALL_ADDRESS");
        } catch {}
        multicallAddress = (useCbMulticall || _useDelegateCall()) ? MULTICALL3_DELEGATECALL_ADDRESS : MULTICALL3_ADDRESS;
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ///                                Public Functions                                ///
    //////////////////////////////////////////////////////////////////////////////////////

    /// Step 1
    /// ======
    /// Generate a transaction approval data to sign. This method should be called by a threshold of
    /// multisig owners.
    ///
    /// For non-nested multisigs, the signatures can then be used to execute the transaction (see step 3).
    ///
    /// For nested multisigs, the signatures can be used to execute an approval transaction for each
    /// multisig (see step 2).
    ///
    /// @param safes A list of nested safes (excluding the executing safe returned by `_ownerSafe`).
    function sign(address[] memory safes) public {
        safes = _appendOwnerSafe({safes: safes});

        // Snapshot and restore Safe nonce after simulation, otherwise the data logged to sign
        // would not match the actual data we need to sign, because the simulation
        // would increment the nonce.
        uint256[] memory originalNonces = new uint256[](safes.length);
        for (uint256 i; i < safes.length; i++) {
            originalNonces[i] = _getNonce({safe: safes[i]});
        }

        (bytes[] memory datas, uint256 value) = _transactionDatas({safes: safes});

        vm.startMappingRecording();
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _simulateForSigner({safes: safes, datas: datas, value: value});
        (StateDiff.MappingParent[] memory parents, string memory json) =
            StateDiff.collectStateDiff(StateDiff.CollectStateDiffOpts({accesses: accesses, simPayload: simPayload}));
        vm.stopMappingRecording();

        _postSign({accesses: accesses, simPayload: simPayload});
        _postCheck({accesses: accesses, simPayload: simPayload});

        // Restore the original nonce.
        for (uint256 i; i < safes.length; i++) {
            vm.store({target: safes[i], slot: SAFE_NONCE_SLOT, value: bytes32(originalNonces[i])});
        }

        bytes memory txData = _encodeTransactionData({safe: safes[0], data: datas[0], value: value});
        StateDiff.recordStateDiff({json: json, parents: parents, txData: txData, targetSafe: _ownerSafe()});

        _printDataToSign({safe: safes[0], data: datas[0], value: value, txData: txData});
    }

    /// Step 1.1 (optional)
    /// ======
    /// Verify the signatures generated from step 1 are valid.
    /// This allows transactions to be pre-signed and stored safely before execution.
    ///
    /// @param safes      A list of nested safes (excluding the executing safe returned by `_ownerSafe`).
    /// @param signatures The signatures to verify (concatenated, 65-bytes per sig).
    function verify(address[] memory safes, bytes memory signatures) public view {
        safes = _appendOwnerSafe({safes: safes});
        (bytes[] memory datas, uint256 value) = _transactionDatas({safes: safes});
        _checkSignatures({safe: safes[0], data: datas[0], value: value, signatures: signatures});
    }

    /// Step 2 (optional for non-nested setups)
    /// ======
    /// Execute an approval transaction. This method should be called by a facilitator
    /// (non-signer), once for each of the multisigs involved in the nested multisig,
    /// after collecting a threshold of signatures for each multisig (see step 1).
    ///
    /// For multiple layers of nesting, this should be called for each layer of nesting (once
    /// the inner multisigs have registered their approval). The array of safes passed to
    /// `safes` should get smaller by one for each layer of nesting.
    ///
    /// @param safes      A list of nested safes (excluding the executing safe returned by `_ownerSafe`).
    /// @param signatures The signatures from step 1 (concatenated, 65-bytes per sig)
    function approve(address[] memory safes, bytes memory signatures) public {
        safes = _appendOwnerSafe({safes: safes});
        (bytes[] memory datas, uint256 value) = _transactionDatas({safes: safes});
        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) =
            _executeTransaction({safe: safes[0], data: datas[0], value: value, signatures: signatures, broadcast: true});
        _postApprove({accesses: accesses, simPayload: simPayload});
    }

    /// Step 2.1 (optional)
    /// ======
    /// Simulate the transaction. This method should be called by a facilitator (non-signer), after all of the
    /// signatures have been collected (non-nested case, see step 1), or the approval transactions have been
    /// submitted onchain (nested case, see step 2, in which case `signatures` can be empty).
    ///
    /// Differs from `run` in that you can override the safe nonce for simulation purposes.
    ///
    /// @param signatures The signatures from step 1 (concatenated, 65-bytes per sig)
    function simulate(bytes memory signatures) public {
        address ownerSafe = _ownerSafe();
        (bytes[] memory datas, uint256 value) = _transactionDatas({safes: _toArray(ownerSafe)});

        vm.store({target: ownerSafe, slot: SAFE_NONCE_SLOT, value: bytes32(_getNonce({safe: ownerSafe}))});

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) = _executeTransaction({
            safe: ownerSafe, data: datas[0], value: value, signatures: signatures, broadcast: false
        });

        _postRun({accesses: accesses, simPayload: simPayload});
        _postCheck({accesses: accesses, simPayload: simPayload});
    }

    /// Step 3
    /// ======
    /// Execute the transaction. This method should be called by a facilitator (non-signer), after all of the
    /// signatures have been collected (non-nested case, see step 1), or the approval transactions have been
    /// submitted onchain (nested case, see step 2, in which case `signatures` can be empty).
    ///
    /// @param signatures The signatures from step 1 (concatenated, 65-bytes per sig)
    function run(bytes memory signatures) public {
        address ownerSafe = _ownerSafe();
        (bytes[] memory datas, uint256 value) = _transactionDatas({safes: _toArray(ownerSafe)});

        (Vm.AccountAccess[] memory accesses, Simulation.Payload memory simPayload) = _executeTransaction({
            safe: ownerSafe, data: datas[0], value: value, signatures: signatures, broadcast: true
        });

        _postRun({accesses: accesses, simPayload: simPayload});
        _postCheck({accesses: accesses, simPayload: simPayload});
    }

    //////////////////////////////////////////////////////////////////////////////////////
    ///                               Internal Functions                               ///
    //////////////////////////////////////////////////////////////////////////////////////

    function _appendOwnerSafe(address[] memory safes) internal view returns (address[] memory) {
        address[] memory extendedSafes = new address[](safes.length + 1);
        for (uint256 i; i < safes.length; i++) {
            extendedSafes[i] = safes[i];
        }
        extendedSafes[extendedSafes.length - 1] = _ownerSafe();
        return extendedSafes;
    }

    function _transactionDatas(address[] memory safes) private view returns (bytes[] memory datas, uint256 value) {
        // Build the calls and sum the values
        IMulticall3.Call3Value[] memory calls = _buildCalls();
        for (uint256 i; i < calls.length; i++) {
            value += calls[i].value;
        }

        // The very last call is the actual (aggregated) call to execute
        datas = new bytes[](safes.length);
        datas[datas.length - 1] = abi.encodeCall(IMulticall3.aggregate3Value, (calls));

        if (_useDelegateCall()) {
            datas[datas.length - 1] = abi.encodeCall(CBMulticall.aggregate3, (_toCall3Array(calls)));
        }

        // The first n-1 calls are the nested approval calls
        uint256 valueForCallToApprove = value;
        for (uint256 i = safes.length - 1; i > 0; i--) {
            address targetSafe = safes[i];
            bytes memory callToApprove = datas[i];

            IMulticall3.Call3[] memory approvalCall = new IMulticall3.Call3[](1);
            approvalCall[0] =
                _generateApproveCall({safe: targetSafe, data: callToApprove, value: valueForCallToApprove});
            datas[i - 1] = abi.encodeCall(IMulticall3.aggregate3, (approvalCall));

            valueForCallToApprove = 0;
        }
    }

    /// @dev Converts `IMulticall3.Call3Value` calls into `CBMulticall.Call3` calls for delegatecall mode.
    ///      All `value` fields must be zero; delegatecall mode does not support per-call value routing.
    function _toCall3Array(IMulticall3.Call3Value[] memory calls) private pure returns (CBMulticall.Call3[] memory) {
        CBMulticall.Call3[] memory dCalls = new CBMulticall.Call3[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            // Delegatecall mode relies on the Safe's `msg.value` handling rather than per-call value routing.
            // Enforce that no per-call value is specified when using delegatecall mode.
            require(calls[i].value == 0, "MultisigScript: delegatecall mode does not support call value");
            dCalls[i] = CBMulticall.Call3({
                target: calls[i].target, allowFailure: calls[i].allowFailure, callData: calls[i].callData
            });
        }
        return dCalls;
    }

    function _generateApproveCall(address safe, bytes memory data, uint256 value)
        internal
        view
        returns (IMulticall3.Call3 memory)
    {
        bytes32 hash = _getTransactionHash({safe: safe, data: data, value: value});

        console.log("---\nNested hash for safe %s:", safe);
        console.logBytes32(hash);

        return IMulticall3.Call3({
            target: safe, allowFailure: false, callData: abi.encodeCall(IGnosisSafe(safe).approveHash, (hash))
        });
    }

    function _printDataToSign(address safe, bytes memory data, uint256 value, bytes memory txData) internal {
        bytes32 hash = _getTransactionHash({safe: safe, data: data, value: value});

        emit DataToSign({data: txData});

        console.log("---\nIf submitting onchain, call Safe.approveHash on %s with the following hash:", safe);
        console.logBytes32(hash);

        console.log("---\nData to sign:");
        console.log("vvvvvvvv");
        console.logBytes(txData);
        console.log("^^^^^^^^\n");

        console.log("########## IMPORTANT ##########");
        console.log(
            // solhint-disable-next-line max-line-length
            "Please make sure that the 'Data to sign' displayed above matches what you see in the simulation and on your hardware wallet."
        );
        console.log("This is a critical step that must not be skipped.");
        console.log("###############################");
    }

    function _executeTransaction(
        address safe,
        bytes memory data,
        uint256 value,
        bytes memory signatures,
        bool broadcast
    ) internal returns (Vm.AccountAccess[] memory, Simulation.Payload memory) {
        bytes32 hash = _getTransactionHash({safe: safe, data: data, value: value});
        signatures = Signatures.prepareSignatures({safe: safe, hash: hash, signatures: signatures});

        bytes memory simData = _execTransactionCalldata({safe: safe, data: data, value: value, signatures: signatures});
        Simulation.logSimulationLink({to: safe, data: simData, from: msg.sender});

        vm.startStateDiffRecording();
        bool success =
            _execTransaction({safe: safe, data: data, value: value, signatures: signatures, broadcast: broadcast});
        Vm.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();
        require(success, "MultisigBase::_executeTransaction: Transaction failed");
        require(accesses.length > 0, "MultisigBase::_executeTransaction: No state changes");

        // This can be used to e.g. call out to the Tenderly API and get additional
        // data about the state diff before broadcasting the transaction.
        Simulation.Payload memory simPayload = Simulation.Payload({
            from: msg.sender, to: safe, data: simData, stateOverrides: new Simulation.StateOverride[](0)
        });
        return (accesses, simPayload);
    }

    function _simulateForSigner(address[] memory safes, bytes[] memory datas, uint256 value)
        internal
        returns (Vm.AccountAccess[] memory, Simulation.Payload memory)
    {
        IMulticall3.Call3[] memory calls = _simulateForSignerCalls({safes: safes, datas: datas, value: value});

        bytes32 firstCallDataHash = _getTransactionHash({safe: safes[0], data: datas[0], value: value});

        // Now define the state overrides for the simulation.
        Simulation.StateOverride[] memory overrides = _overrides({safes: safes, firstCallDataHash: firstCallDataHash});

        bytes memory txData = abi.encodeCall(IMulticall3.aggregate3, (calls));
        console.log("---\nSimulation link:");
        // solhint-disable max-line-length
        Simulation.logSimulationLink({to: multicallAddress, data: txData, from: msg.sender, overrides: overrides});

        // Forge simulation of the data logged in the link. If the simulation fails
        // we revert to make it explicit that the simulation failed.
        Simulation.Payload memory simPayload =
            Simulation.Payload({to: multicallAddress, data: txData, from: msg.sender, stateOverrides: overrides});
        Vm.AccountAccess[] memory accesses = Simulation.simulateFromSimPayload({simPayload: simPayload});
        return (accesses, simPayload);
    }

    function _simulateForSignerCalls(address[] memory safes, bytes[] memory datas, uint256 value)
        private
        view
        returns (IMulticall3.Call3[] memory)
    {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](safes.length);
        for (uint256 i; i < safes.length; i++) {
            address signer = i == 0 ? msg.sender : safes[i - 1];

            calls[i] = IMulticall3.Call3({
                target: safes[i],
                allowFailure: false,
                callData: _execTransactionCalldata({
                    safe: safes[i],
                    data: datas[i],
                    value: value,
                    signatures: Signatures.genPrevalidatedSignature(signer)
                })
            });
        }

        return calls;
    }

    // The state change simulation can set the threshold, owner address and/or nonce.
    // This allows simulation of the final transaction by overriding the threshold to 1.
    // State changes reflected in the simulation as a result of these overrides will
    // not be reflected in the prod execution.
    function _overrides(address[] memory safes, bytes32 firstCallDataHash)
        internal
        view
        returns (Simulation.StateOverride[] memory)
    {
        Simulation.StateOverride[] memory simOverrides = _simulationOverrides();
        Simulation.StateOverride[] memory overrides = new Simulation.StateOverride[](safes.length + simOverrides.length);

        uint256 nonce = _getNonce({safe: safes[0]});
        overrides[0] = Simulation.overrideSafeThresholdApprovalAndNonce({
            safe: safes[0], nonce: nonce, owner: msg.sender, dataHash: firstCallDataHash
        });

        for (uint256 i = 1; i < safes.length; i++) {
            overrides[i] =
                Simulation.overrideSafeThresholdAndNonce({safe: safes[i], nonce: _getNonce({safe: safes[i]})});
        }

        for (uint256 i; i < simOverrides.length; i++) {
            overrides[i + safes.length] = simOverrides[i];
        }

        return overrides;
    }

    // Get the nonce to use for the given safe, for signing and simulations.
    //
    // If you override it, ensure that the behavior is correct for all contexts.
    // As an example, if you are pre-signing a message that needs safe.nonce+1 (before
    // safe.nonce is executed), you should explicitly set the nonce value with an env var.
    // Overriding this method with safe.nonce+1 will cause issues upon execution because
    // the transaction hash will differ from the one signed.
    //
    // The process for determining a nonce override is as follows:
    //   1. We look for an env var of the name SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}. For example,
    //      SAFE_NONCE_0X6DF4742A3C28790E63FE933F7D108FE9FCE51EA4.
    //   2. If it exists, we use it as the nonce override for the safe.
    //   3. If it does not exist, we do the same for the SAFE_NONCE env var.
    //   4. Otherwise we fallback to the safe's current nonce (no override).
    function _getNonce(address safe) internal view virtual returns (uint256 nonce) {
        uint256 safeNonce = IGnosisSafe(safe).nonce();
        nonce = safeNonce;

        // first try SAFE_NONCE
        try vm.envUint({name: "SAFE_NONCE"}) {
            nonce = vm.envUint({name: "SAFE_NONCE"});
        } catch {}

        // then try SAFE_NONCE_{UPPERCASE_SAFE_ADDRESS}
        string memory envVarName = string.concat("SAFE_NONCE_", vm.toUppercase({input: vm.toString({value: safe})}));
        try vm.envUint({name: envVarName}) {
            nonce = vm.envUint({name: envVarName});
        } catch {}

        // print if any override
        if (nonce != safeNonce) {
            console.log("Overriding nonce for safe %s: %d -> %d", safe, safeNonce, nonce);
        }
    }

    function _checkSignatures(address safe, bytes memory data, uint256 value, bytes memory signatures) internal view {
        bytes32 hash = _getTransactionHash({safe: safe, data: data, value: value});
        signatures = Signatures.prepareSignatures({safe: safe, hash: hash, signatures: signatures});
        IGnosisSafe(safe).checkSignatures({dataHash: hash, data: data, signatures: signatures});
    }

    function _getTransactionHash(address safe, bytes memory data, uint256 value) internal view returns (bytes32) {
        return keccak256(_encodeTransactionData({safe: safe, data: data, value: value}));
    }

    function _encodeTransactionData(address safe, bytes memory data, uint256 value)
        internal
        view
        returns (bytes memory)
    {
        return IGnosisSafe(safe)
            .encodeTransactionData({
                to: multicallAddress,
                value: value,
                data: data,
                operation: _getOperation(value),
                safeTxGas: 0,
                baseGas: 0,
                gasPrice: 0,
                gasToken: address(0),
                refundReceiver: address(0),
                _nonce: _getNonce(safe)
            });
    }

    function _execTransactionCalldata(address safe, bytes memory data, uint256 value, bytes memory signatures)
        internal
        view
        returns (bytes memory)
    {
        return abi.encodeCall(
            IGnosisSafe(safe).execTransaction,
            (multicallAddress, value, data, _getOperation(value), 0, 0, 0, address(0), payable(address(0)), signatures)
        );
    }

    function _execTransaction(address safe, bytes memory data, uint256 value, bytes memory signatures, bool broadcast)
        internal
        returns (bool)
    {
        if (broadcast) {
            vm.broadcast();
        }
        return IGnosisSafe(safe)
            .execTransaction({
                to: multicallAddress,
                value: value,
                data: data,
                operation: _getOperation(value),
                safeTxGas: 0,
                baseGas: 0,
                gasPrice: 0,
                gasToken: address(0),
                refundReceiver: payable(address(0)),
                signatures: signatures
            });
    }

    function _toArray(address addr) internal pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = addr;
        return array;
    }

    function _toArray(address address1, address address2) internal pure returns (address[] memory) {
        address[] memory array = new address[](2);
        array[0] = address1;
        array[1] = address2;
        return array;
    }

    function _getOperation(uint256 value) private view returns (Enum.Operation) {
        if (multicallAddress == MULTICALL3_DELEGATECALL_ADDRESS || value == 0) {
            return Enum.Operation.DelegateCall;
        }

        return Enum.Operation.Call;
    }
}
