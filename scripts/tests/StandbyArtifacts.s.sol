// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ArtifactVm {
    function envString(string calldata name) external view returns (string memory);
    function writeJson(string calldata json, string calldata path) external;
    function readFile(string calldata path) external view returns (string memory);
    function parseJsonUint(string calldata json, string calldata key) external pure returns (uint256);
}

contract ArtifactScript {
    ArtifactVm internal constant vm = ArtifactVm(address(uint160(uint256(keccak256("hevm cheat code")))));
}

contract DeployAggregateVerifier is ArtifactScript {
    function run() external {
        vm.writeJson(
            '{"aggregateVerifier":"0x0000000000000000000000000000000000002222"}', vm.envString("ADDRESSES_JSON")
        );
    }
}

contract UpdateVerifierHashes is ArtifactScript {
    function check() external {
        vm.writeJson('{"gameCount":7}', vm.envString("PRESTATE_JSON"));
    }
}

contract VerifyVerifierHashes is ArtifactScript {
    function checkAfterExecution() external view {
        require(vm.parseJsonUint(vm.readFile(vm.envString("PRESTATE_JSON")), ".gameCount") == 7, "prestate mismatch");
    }
}
