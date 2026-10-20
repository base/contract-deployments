// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Enum} from "@base-contracts/scripts/universal/IGnosisSafe.sol";
import {Call3, Result} from "@base-contracts/interfaces/universal/ICBMulticall.sol";

contract SimulationSafe {
    uint256[5] private reserved;
    uint256 public nonce;
    uint256[2] private reservedAfterNonce;
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    function approveHash(bytes32 hash) external {
        approvedHashes[msg.sender][hash] = 1;
    }

    function getThreshold() external pure returns (uint256) {
        return 1;
    }

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256,
        uint256,
        uint256,
        address,
        address,
        uint256 transactionNonce
    ) external view returns (bytes memory) {
        return abi.encodePacked(
            hex"1901",
            keccak256(abi.encode(address(this))),
            keccak256(abi.encode(to, value, data, operation, transactionNonce))
        );
    }

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256,
        uint256,
        uint256,
        address,
        address,
        bytes calldata
    ) external payable returns (bool) {
        require(operation == Enum.Operation.Call && value == 0, "fixture expects a zero-value direct call");
        nonce++;
        (bool success,) = to.call(data);
        require(success, "fixture target failed");
        return success;
    }
}

contract SimulationMulticall {
    function aggregate3(Call3[] calldata calls) external payable returns (Result[] memory results) {
        require(calls.length > 0 && calls.length <= 2, "fixture expects direct or singly nested signing");
        results = new Result[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            (results[i].success, results[i].returnData) = calls[i].target.call(calls[i].callData);
            require(results[i].success || calls[i].allowFailure, "fixture Safe simulation failed");
        }
    }
}
