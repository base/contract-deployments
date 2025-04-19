// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Registry} from "basenames/L2/Registry.sol";
import {BaseRegistrar} from "basenames/L2/BaseRegistrar.sol";
import {L2Resolver, NameResolver, Multicallable} from "basenames/L2/L2Resolver.sol";
import {BASE_ETH_NODE} from "basenames/util/Constants.sol";
import {
    MultisigBuilder,
    Simulator,
    IMulticall3,
    IGnosisSafe,
    console,
    Enum
} from "@base-contracts/script/universal/MultisigBuilder.sol";
import { Vm } from "forge-std/Vm.sol";


interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 id) external;
}

interface AddrResolver {
    function setAddr(bytes32 node, address addr) external;
}

// This script will be signed ahead of our gas limit increase but isn't expected to be
// executed. It will be available to us in the event we need to quickly rollback the gas limit.
contract DisburseBasenames is MultisigBuilder {
    address internal ECOSYSTEM_MULTISIG = vm.envAddress("ECOSYSTEM_MULTISIG");
    address internal BASE_REGISTRAR_ADDR = vm.envAddress("BASE_REGISTRAR_ADDR");
    address internal REGISTRY_ADDR = vm.envAddress("REGISTRY_ADDR");
    address internal L2_RESOLVER_ADDR = vm.envAddress("L2_RESOLVER_ADDR");
    uint256 NONCE;

    function signWithNonce(uint256 nonce_) public {
        NONCE = nonce_;
        sign();
    }

    function executeWithNonce(uint256 nonce_, bytes calldata signatures) public {
        NONCE = nonce_;
        run(signatures);
    }

    struct Disbursement {
        Single[] singles;
    }

    struct Single {
        address addr;
        string name;
    }

    function _parseFile() internal view returns (Disbursement memory) {
        string memory json = vm.readFile("disbursement.json");
        bytes memory data = vm.parseJson(json);
        return abi.decode(data, (Disbursement));
    } 

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        Disbursement memory allData = _parseFile();
        uint256 callcount = allData.singles.length * 5; // 5 calls per disbursement
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](callcount);

        uint256 accumulator;
        for(uint256 i; i < allData.singles.length; i++) {
            IMulticall3.Call3[] memory singleCalls = new IMulticall3.Call3[](5);
            singleCalls = _buildCallsForSingle(allData.singles[i]);
            calls[accumulator++] = singleCalls[0];
            calls[accumulator++] = singleCalls[1];
            calls[accumulator++] = singleCalls[2];
            calls[accumulator++] = singleCalls[3];
            calls[accumulator++] = singleCalls[4];
        }

        return calls;
    }

    function _buildCallsForSingle(Single memory single) internal view returns (IMulticall3.Call3[] memory) {
        uint256 id = _getIdFromName(single.name);
        address addr = single.addr;
        string memory name = single.name;
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](5);

        // CALL 0 :: call reclaim to give the multisig permission to edit records for this name.
        calls[0] = IMulticall3.Call3({
            target: BASE_REGISTRAR_ADDR,
            allowFailure: false,
            callData: abi.encodeWithSelector(BaseRegistrar.reclaim.selector, id, ECOSYSTEM_MULTISIG)
        });

        // CALL 1 :: set the L2 resolver as the resolver for the node in the regsitry 
        calls[1] = IMulticall3.Call3({
            target: REGISTRY_ADDR,
            allowFailure: false,
            callData: abi.encodeWithSelector(Registry.setResolver.selector, _getNodeFromId(id), L2_RESOLVER_ADDR)
        });

        // CALL 2 :: set the resolver data for the name using `setAddr` and `setName` encoded for multicall.
        calls[2] = IMulticall3.Call3({
            target: L2_RESOLVER_ADDR,
            allowFailure: false,
            callData: _buildResolverData(_getNodeFromId(id), addr, name)
        });

        // CALL 3 :: call reclaim on behalf of the new owner. 
        calls[3] = IMulticall3.Call3({
            target: BASE_REGISTRAR_ADDR,
            allowFailure: false,
            callData: abi.encodeWithSelector(BaseRegistrar.reclaim.selector, id, addr)
        });

        // CALL 4 :: call safeTransferFrom to transfer the name to the new owner. 
        calls[4] = IMulticall3.Call3({
            target: BASE_REGISTRAR_ADDR,
            allowFailure: false,
            callData: abi.encodeWithSelector(IERC721.safeTransferFrom.selector, ECOSYSTEM_MULTISIG, addr, id)
        });

        return calls;
    }

    function _getNodeFromId(uint256 id) internal pure returns (bytes32 node) {
        node = keccak256(abi.encodePacked(BASE_ETH_NODE, bytes32(id)));
    }

    function _getIdFromName(string memory name) internal pure returns (uint256 id) {
        id = uint256(keccak256(bytes(name)));
    }

    function _buildResolverData(bytes32 node, address addr, string memory name) internal pure returns (bytes memory data) {
        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodeWithSelector(AddrResolver.setAddr.selector, node, addr);
        multicallData[1] = abi.encodeWithSelector(NameResolver.setName.selector, node, string.concat(name,".base.eth"));
        return abi.encodeWithSelector(Multicallable.multicallWithNodeCheck.selector, node, multicallData);
    }

    /// @dev Multisig overrides for simulation and execution
    function _ownerSafe() internal override view returns (address) {
        return ECOSYSTEM_MULTISIG;
    }

    function _addOverrides(address _safe) internal override view returns (SimulationStateOverride memory) {
        IGnosisSafe safe = IGnosisSafe(payable(_safe));
        uint256 _nonce = _getNonce(safe);
        return overrideSafeThresholdOwnerAndNonce(_safe, DEFAULT_SENDER, _nonce);
    }

    function _getNonce(IGnosisSafe) internal view override returns (uint256) {
        return NONCE;
    }

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal view override {
        Disbursement memory data = _parseFile();
        for(uint256 i; i < data.singles.length; i++){
            Single memory s = data.singles[i];
            bytes32 node = _getNodeFromId(_getIdFromName(s.name));
            assert(Registry(REGISTRY_ADDR).owner(_getNodeFromId(_getIdFromName(s.name))) == s.addr);
            assert(Registry(REGISTRY_ADDR).resolver(_getNodeFromId(_getIdFromName(s.name))) == L2_RESOLVER_ADDR);
            assert(BaseRegistrar(BASE_REGISTRAR_ADDR).ownerOf(_getIdFromName(s.name)) == s.addr);
            assert(L2Resolver(L2_RESOLVER_ADDR).addr(node) == s.addr);
            assert(keccak256(bytes(L2Resolver(L2_RESOLVER_ADDR).name(node))) == keccak256(bytes(string.concat(s.name,".base.eth"))));
        }
    }
}
