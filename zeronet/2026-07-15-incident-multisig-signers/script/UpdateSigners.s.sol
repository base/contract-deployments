// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {MultisigScript, Enum} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";

interface ISafeOwnerManager {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
    function isOwner(address owner) external view returns (bool);
    function addOwnerWithThreshold(address owner, uint256 threshold) external;
    function removeOwner(address prevOwner, address owner, uint256 threshold) external;
}

contract UpdateSigners is MultisigScript {
    using stdJson for string;

    address public constant SENTINEL_OWNERS = address(0x1);
    uint256 public constant EXPECTED_OWNERS_TO_ADD = 1;
    uint256 public constant EXPECTED_OWNERS_TO_REMOVE = 2;

    address public immutable OWNER_SAFE = vm.envAddress("OWNER_SAFE");
    uint256 public immutable THRESHOLD;
    address[] public EXISTING_OWNERS;

    address[] public OWNERS_TO_ADD;
    address[] public OWNERS_TO_REMOVE;

    mapping(address => address) public ownerToPrevOwner;
    mapping(address => address) public ownerToNextOwner;
    mapping(address => bool) public expectedOwner;

    constructor() {
        ISafeOwnerManager ownerSafe = ISafeOwnerManager(OWNER_SAFE);
        THRESHOLD = ownerSafe.getThreshold();
        EXISTING_OWNERS = ownerSafe.getOwners();

        string memory path = string.concat(vm.projectRoot(), "/OwnerDiff.json");
        string memory jsonData = vm.readFile(path);

        OWNERS_TO_ADD = abi.decode(jsonData.parseRaw(".OwnersToAdd"), (address[]));
        OWNERS_TO_REMOVE = abi.decode(jsonData.parseRaw(".OwnersToRemove"), (address[]));
    }

    function setUp() external {
        require(OWNERS_TO_ADD.length == EXPECTED_OWNERS_TO_ADD, "Precheck 00");
        require(OWNERS_TO_REMOVE.length == EXPECTED_OWNERS_TO_REMOVE, "Precheck 01");
        require(EXISTING_OWNERS.length + OWNERS_TO_ADD.length >= OWNERS_TO_REMOVE.length, "Precheck 02");

        uint256 expectedLength = EXISTING_OWNERS.length + OWNERS_TO_ADD.length - OWNERS_TO_REMOVE.length;
        require(expectedLength >= THRESHOLD, "Precheck 03");

        ISafeOwnerManager ownerSafe = ISafeOwnerManager(OWNER_SAFE);
        address prevOwner = SENTINEL_OWNERS;

        for (uint256 i = OWNERS_TO_ADD.length; i > 0; i--) {
            uint256 index = i - 1;
            address ownerToAdd = OWNERS_TO_ADD[index];

            _validateOwnerAddress(ownerToAdd);
            require(!ownerSafe.isOwner(ownerToAdd), "Precheck 04");
            require(!expectedOwner[ownerToAdd], "Precheck 05");

            ownerToPrevOwner[ownerToAdd] = prevOwner;
            ownerToNextOwner[prevOwner] = ownerToAdd;
            prevOwner = ownerToAdd;
            expectedOwner[ownerToAdd] = true;
        }

        for (uint256 i; i < EXISTING_OWNERS.length; i++) {
            _validateOwnerAddress(EXISTING_OWNERS[i]);

            ownerToPrevOwner[EXISTING_OWNERS[i]] = prevOwner;
            ownerToNextOwner[prevOwner] = EXISTING_OWNERS[i];
            prevOwner = EXISTING_OWNERS[i];
            expectedOwner[EXISTING_OWNERS[i]] = true;
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            address ownerToRemove = OWNERS_TO_REMOVE[i];

            _validateOwnerAddress(ownerToRemove);
            require(ownerSafe.isOwner(ownerToRemove), "Precheck 06");
            require(expectedOwner[ownerToRemove], "Precheck 07");

            expectedOwner[ownerToRemove] = false;

            address nextOwner = ownerToNextOwner[ownerToRemove];
            address prevPtr = ownerToPrevOwner[ownerToRemove];
            ownerToPrevOwner[nextOwner] = prevPtr;
            ownerToNextOwner[prevPtr] = nextOwner;
        }
    }

    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        ISafeOwnerManager ownerSafe = ISafeOwnerManager(OWNER_SAFE);
        address[] memory postCheckOwners = ownerSafe.getOwners();
        uint256 postCheckThreshold = ownerSafe.getThreshold();

        uint256 expectedLength = EXISTING_OWNERS.length + OWNERS_TO_ADD.length - OWNERS_TO_REMOVE.length;

        require(postCheckThreshold == THRESHOLD, "Postcheck 00");
        require(postCheckOwners.length == expectedLength, "Postcheck 01");

        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            require(ownerSafe.isOwner(OWNERS_TO_ADD[i]), "Postcheck 02");
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            require(!ownerSafe.isOwner(OWNERS_TO_REMOVE[i]), "Postcheck 03");
        }

        for (uint256 i; i < postCheckOwners.length; i++) {
            require(expectedOwner[postCheckOwners[i]], "Postcheck 04");
        }
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](OWNERS_TO_ADD.length + OWNERS_TO_REMOVE.length);

        for (uint256 i; i < OWNERS_TO_ADD.length; i++) {
            calls[i] = Call({
                operation: Enum.Operation.Call,
                target: OWNER_SAFE,
                data: abi.encodeCall(ISafeOwnerManager.addOwnerWithThreshold, (OWNERS_TO_ADD[i], THRESHOLD)),
                value: 0
            });
        }

        for (uint256 i; i < OWNERS_TO_REMOVE.length; i++) {
            calls[OWNERS_TO_ADD.length + i] = Call({
                operation: Enum.Operation.Call,
                target: OWNER_SAFE,
                data: abi.encodeCall(
                    ISafeOwnerManager.removeOwner,
                    (ownerToPrevOwner[OWNERS_TO_REMOVE[i]], OWNERS_TO_REMOVE[i], THRESHOLD)
                ),
                value: 0
            });
        }

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }

    function _validateOwnerAddress(address owner) internal pure {
        require(owner != address(0), "owner zero");
        require(owner != SENTINEL_OWNERS, "owner sentinel");
    }
}
