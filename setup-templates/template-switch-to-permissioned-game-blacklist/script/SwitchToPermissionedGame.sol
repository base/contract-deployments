// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {IMulticall3} from "forge-std/interfaces/IMulticall3.sol";
import {console} from "forge-std/console.sol";
import {IAnchorStateRegistry} from "@base-contracts/src/dispute/FaultDisputeGame.sol";
import {SystemConfig} from "@base-contracts/src/L1/SystemConfig.sol";
import {IDisputeGame, GameStatus} from "@base-contracts/src/dispute/AnchorStateRegistry.sol";
import {IDisputeGameFactory} from "@base-contracts/interfaces/dispute/IDisputeGameFactory.sol";
import {FaultDisputeGame} from "@base-contracts/src/dispute/PermissionedDisputeGame.sol";
import {GameTypes, GameType} from "@base-contracts/src/dispute/lib/Types.sol";
import {MultisigScript} from "@base-contracts/script/universal/MultisigScript.sol";
import {Simulation} from "@base-contracts/script/universal/Simulation.sol";
import {Enum} from "@base-contracts/script/universal/IGnosisSafe.sol";

/// @notice This script updates the FaultDisputeGame and PermissionedDisputeGame implementations in the
///         DisputeGameFactory contract.
contract SwitchToPermissionedGame is MultisigScript {
    using stdJson for string;

    // TODO: Confirm expected version
    string public constant EXPECTED_VERSION = "1.4.1";

    address public immutable OWNER_SAFE;
    uint64 public immutable L2_DIVERGENCE_BLOCK_NUMBER;
    string public RAW_ADDRESSES_TO_BLACKLIST;

    SystemConfig internal _SYSTEM_CONFIG = SystemConfig(vm.envAddress("SYSTEM_CONFIG"));

    IAnchorStateRegistry anchorStateRegistry;
    IDisputeGame[] gamesToBlacklist;

    constructor() {
        OWNER_SAFE = vm.envAddress("OWNER_SAFE");
        RAW_ADDRESSES_TO_BLACKLIST = vm.envString("ADDRESSES_TO_BLACKLIST");
        L2_DIVERGENCE_BLOCK_NUMBER = uint64(vm.envUint("L2_DIVERGENCE_BLOCK_NUMBER"));
    }

    function setUp() public {
        IDisputeGameFactory dgfProxy = IDisputeGameFactory(_SYSTEM_CONFIG.disputeGameFactory());
        FaultDisputeGame currentFdg = FaultDisputeGame(address(dgfProxy.gameImpls(GameTypes.CANNON)));
        anchorStateRegistry = currentFdg.anchorStateRegistry();

        // Split by commas
        string[] memory parts = vm.split(RAW_ADDRESSES_TO_BLACKLIST, ",");

        // vm.split("", ",") return [""] with size 1
        if (parts.length == 0 || (parts.length == 1 && bytes(parts[0]).length == 0)) {
            console.log("searching for addresses to blacklist");
            getGamesToBlacklist(dgfProxy);
        } else {
            console.log("using provided address_to_blacklist list");
            for (uint256 i; i < parts.length; i++) {
                address address_to_blacklist = vm.parseAddress(parts[i]);
                gamesToBlacklist.push(IDisputeGame(address_to_blacklist));
            }
        }

        console.log("total games to blacklist", gamesToBlacklist.length);
    }

    function getGamesToBlacklist(IDisputeGameFactory dgfProxy) internal {
        uint256 totalNumGames = dgfProxy.gameCount();
        console.log("total games to search", totalNumGames);

        for (uint256 i = 0; i < totalNumGames; i = i + 1) {
            (,, IDisputeGame game) = dgfProxy.gameAtIndex(i);
            if (game.status() == GameStatus.IN_PROGRESS && game.l2SequenceNumber() >= L2_DIVERGENCE_BLOCK_NUMBER) {
                // this game is in progress and challenges a block at or after the divergence block
                gamesToBlacklist.push(game);
            }
        }
    }

    // Confirm the CURRENT_RETIREMENT_TIMESTAMP is updated to the block time.
    function _postCheck(Vm.AccountAccess[] memory, Simulation.Payload memory) internal view override {
        for (uint256 i = 0; i < gamesToBlacklist.length; i = i + 1) {
            require(anchorStateRegistry.isGameBlacklisted(gamesToBlacklist[i]), "post-110");
        }
        require(
            GameType.unwrap(anchorStateRegistry.respectedGameType()) == GameType.unwrap(GameTypes.PERMISSIONED_CANNON),
            "post-111"
        );
    }

    function _buildCalls() internal view override returns (Call[] memory) {
        Call[] memory calls = new Call[](gamesToBlacklist.length + 1);

        calls[0] = Call({
            operation: Enum.Operation.Call,
            target: address(anchorStateRegistry),
            data: abi.encodeCall(IAnchorStateRegistry.setRespectedGameType, (GameTypes.PERMISSIONED_CANNON)),
            value: 0
        });

        for (uint256 i = 0; i < gamesToBlacklist.length; i = i + 1) {
            calls[i + 1] = Call({
                operation: Enum.Operation.Call,
                target: address(anchorStateRegistry),
                data: abi.encodeCall(IAnchorStateRegistry.blacklistDisputeGame, (gamesToBlacklist[i])),
                value: 0
            });
        }

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return OWNER_SAFE;
    }
}
