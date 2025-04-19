// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@base-contracts/script/universal/MultisigBuilder.sol";
import "@eth-optimism-bedrock/contracts/L1/OptimismPortal.sol";

contract RollbackUnpausePortal is MultisigBuilder {
    address constant internal OPTIMISM_PORTAL_PROXY = vm.envAddress("OPTIMISM_PORTAL_PROXY"); // TODO: define OPTIMISM_PORTAL_PROXY=xxx in the .env file
    address constant internal GUARDIAN = vm.envAddress("GUARDIAN"); // TODO: define GUARDIAN=xxx in the .env file

    function _postCheck() internal override view {
        OptimismPortal optimismPortal = OptimismPortal(payable(OPTIMISM_PORTAL_PROXY));
        require(optimismPortal.paused() == false, "UnpausePortal: Portal did not get unpaused");
    }

    function _buildCalls() internal override view returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: OPTIMISM_PORTAL_PROXY,
            allowFailure: false,
            callData: abi.encodeCall(
                OptimismPortal.unpause, ()
            )
        });

        return calls;
    }

    function _ownerSafe() internal override view returns (address) {
        return GUARDIAN;
    }

    function _addOverrides(address _safe) internal override view returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }

    // This transaction expects that there will be a `Pause` transaction before this one
    // but both txs will be signed ahead of time. Need to explicitly override the nonce to 
    // ensure that the correct nonce is used in the sign, simulate and execution steps. 
    function _getNonce(IGnosisSafe) internal override view returns (uint256 nonce) {
        nonce = vm.envUint("ROLLBACK_NONCE");
    }
}
