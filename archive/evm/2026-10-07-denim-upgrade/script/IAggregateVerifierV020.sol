// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {GameType} from "@base-contracts/src/libraries/bridge/Types.sol";

/// @notice Getters of the live AggregateVerifier 0.2.0 used by this task.
/// @dev 0.3.0 removed `BLOCK_INTERVAL()` and `INTERMEDIATE_BLOCK_INTERVAL()` in favour of the `SLOW_*`
///      and `FAST_*` pairs, so the live verifier cannot be read through the 0.3.0 ABI.
interface IAggregateVerifierV020 {
    function gameType() external view returns (GameType);
    function anchorStateRegistry() external view returns (address);
    function DISPUTE_GAME_FACTORY() external view returns (address);
    function DELAYED_WETH() external view returns (address);
    function TEE_VERIFIER() external view returns (address);
    function ZK_VERIFIER() external view returns (address);
    function TEE_IMAGE_HASH() external view returns (bytes32);
    function ZK_RANGE_HASH() external view returns (bytes32);
    function ZK_AGGREGATE_HASH() external view returns (bytes32);
    function CONFIG_HASH() external view returns (bytes32);
    function L2_CHAIN_ID() external view returns (uint256);
    function BLOCK_INTERVAL() external view returns (uint256);
    function INTERMEDIATE_BLOCK_INTERVAL() external view returns (uint256);
    function PROTOCOL_VERSIONS() external view returns (address);
    function L2_GENESIS_BLOCK_NUMBER() external view returns (uint256);
    function L2_GENESIS_TIMESTAMP() external view returns (uint64);
    function L2_BLOCK_TIME() external view returns (uint64);
    function version() external view returns (string memory);
}
