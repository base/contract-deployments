// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Script, console} from "forge-std/Script.sol";
import {IProxyAdmin} from "interfaces/universal/IProxyAdmin.sol";
import {ISemver} from "interfaces/universal/ISemver.sol";
import {AddressAliasHelper} from "src/vendor/AddressAliasHelper.sol";
import {LegacyMigrator} from "./LegacyMigrator.sol";

abstract contract L2Upgrade is Script {
    address internal constant ADMIN = 0x4200000000000000000000000000000000000018;
    address internal constant FACTORY = 0x4200000000000000000000000000000000000017;
    address internal constant VAULT = 0x420000000000000000000000000000000000001b;
    address internal constant REGISTRY = 0x4200000000000000000000000000000000000020;
    address internal constant EAS_PROXY = 0x4200000000000000000000000000000000000021;
    address internal constant MESSENGER = 0x4200000000000000000000000000000000000007;
    address internal constant BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant ERC20_FACTORY = 0x4200000000000000000000000000000000000012;
    address internal constant ERC721_BRIDGE = 0x4200000000000000000000000000000000000014;
    bytes32 internal constant INITIALIZABLE_SLOT = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;
    uint64 internal constant L2_GAS_LIMIT = 300_000;

    address internal immutable ownerSafe = vm.envAddress("PROXY_ADMIN_OWNER");
    address internal immutable factoryBridge = vm.envAddress("FACTORY_BRIDGE");
    uint256 internal immutable remoteChainId = vm.envUint("REMOTE_CHAIN_ID");
    address internal immutable vaultRecipient = vm.envAddress("OPERATOR_FEE_VAULT_RECIPIENT");
    uint256 internal immutable vaultMinimum = vm.envUint("OPERATOR_FEE_VAULT_MIN_WITHDRAWAL_AMOUNT");
    uint8 internal immutable vaultNetwork = uint8(vm.envUint("OPERATOR_FEE_VAULT_WITHDRAWAL_NETWORK"));
    address internal immutable l1Messenger = vm.envAddress("L1_CROSS_DOMAIN_MESSENGER");
    address internal immutable l1Bridge = vm.envAddress("L1_STANDARD_BRIDGE");
    address internal immutable erc20Bridge = vm.envAddress("ERC20_FACTORY_BRIDGE");
    address internal immutable l1ERC721Bridge = vm.envAddress("L1_ERC721_BRIDGE");

    function _migrator() internal view virtual returns (address);

    function _proxies() internal pure returns (address[8] memory) {
        return [FACTORY, VAULT, REGISTRY, EAS_PROXY, MESSENGER, BRIDGE, ERC20_FACTORY, ERC721_BRIDGE];
    }

    function _versions() internal pure returns (string[8] memory) {
        return [string("1.4.2"), "1.1.0", "1.3.1-beta.2", "1.4.1-beta.3", "2.2.0", "1.13.0", "1.10.2", "1.10.0"];
    }

    function _l2Calls(address[8] memory impls) internal view returns (bytes[] memory calls) {
        address[8] memory proxies = _proxies();
        calls = new bytes[](8);
        for (uint256 i; i < 4; i++) {
            calls[i] = abi.encodeCall(IProxyAdmin.upgrade, (payable(proxies[i]), impls[i]));
        }
        address[4] memory counterparts = [l1Messenger, l1Bridge, erc20Bridge, l1ERC721Bridge];
        for (uint256 i; i < 4; i++) {
            calls[i + 4] = abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (
                    payable(proxies[i + 4]),
                    _migrator(),
                    abi.encodeCall(
                        LegacyMigrator.migrate,
                        (impls[i + 4], abi.encodeWithSignature("initialize(address)", counterparts[i]))
                    )
                )
            );
        }
        calls[1] = abi.encodeCall(
            IProxyAdmin.upgradeAndCall,
            (
                payable(VAULT),
                impls[1],
                abi.encodeWithSignature("initialize(address,uint256,uint8)", vaultRecipient, vaultMinimum, vaultNetwork)
            )
        );
    }

    function _replay(address[8] memory impls) internal {
        address aliasOwner = AddressAliasHelper.applyL1ToL2Alias(ownerSafe);
        require(IProxyAdmin(ADMIN).owner() == aliasOwner, "l2 proxy admin owner mismatch");
        require(_uint(FACTORY, "BRIDGE()") == uint160(factoryBridge), "live factory bridge changed");
        require(_uint(FACTORY, "REMOTE_CHAIN_ID()") == remoteChainId, "live remote chain changed");
        require(_uint(VAULT, "RECIPIENT()") == uint160(vaultRecipient), "live operator recipient changed");
        require(_uint(VAULT, "MIN_WITHDRAWAL_AMOUNT()") == vaultMinimum, "live operator minimum changed");
        require(_uint(VAULT, "WITHDRAWAL_NETWORK()") == vaultNetwork, "live operator network changed");
        require(vm.load(VAULT, INITIALIZABLE_SLOT) == bytes32(0), "operator vault already initialized");
        require(_uint(MESSENGER, "OTHER_MESSENGER()") == uint160(l1Messenger), "live L1 messenger changed");
        require(_uint(BRIDGE, "OTHER_BRIDGE()") == uint160(l1Bridge), "live L1 bridge changed");
        require(
            _uint(ERC20_FACTORY, "BRIDGE()") == uint160(erc20Bridge) && erc20Bridge == BRIDGE,
            "live ERC20 bridge changed"
        );
        require(_uint(ERC721_BRIDGE, "OTHER_BRIDGE()") == uint160(l1ERC721Bridge), "live L1 ERC721 bridge changed");
        for (uint256 i = 4; i < 8; i++) {
            uint256 expected = i == 4
                ? uint256(2) << 160
                : i == 6 ? (uint256(uint160(BRIDGE)) << 16) | 2 : i == 7 ? (uint256(uint160(MESSENGER)) << 16) | 2 : 2;
            require(uint256(vm.load(_proxies()[i], bytes32(0))) == expected, "legacy slot zero changed");
        }
        uint256 nonce = _uint(MESSENGER, "messageNonce()");
        bytes32 sender = vm.load(MESSENGER, bytes32(uint256(204)));
        require(sender == bytes32(uint256(0xdead)), "messenger is relaying");
        uint256 totalProcessed = _uint(VAULT, "totalProcessed()");
        bytes[] memory calls = _l2Calls(impls);
        for (uint256 i; i < calls.length; i++) {
            // Deposits are separate transactions. Clear warmth before measuring each one.
            vm.cool(ADMIN);
            vm.cool(_proxies()[i]);
            vm.cool(impls[i]);
            bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
            bytes32 adminSlot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
            vm.coolSlot(ADMIN, bytes32(0));
            vm.coolSlot(ADMIN, implementationSlot);
            vm.coolSlot(_proxies()[i], implementationSlot);
            vm.coolSlot(_proxies()[i], adminSlot);
            if (i == 1) {
                vm.coolSlot(VAULT, INITIALIZABLE_SLOT);
                vm.coolSlot(VAULT, bytes32(uint256(1)));
                vm.coolSlot(VAULT, bytes32(uint256(2)));
            }
            if (i >= 4) {
                vm.cool(_migrator());
                vm.coolSlot(_proxies()[i], bytes32(0));
                for (uint256 slot = 1; slot <= 4; slot++) {
                    vm.coolSlot(_proxies()[i], bytes32(slot));
                }
                vm.coolSlot(MESSENGER, bytes32(uint256(204)));
                vm.coolSlot(MESSENGER, bytes32(uint256(207)));
            }
            vm.prank(aliasOwner);
            uint256 gasBefore = gasleft();
            (bool ok, bytes memory reason) = ADMIN.call{gas: L2_GAS_LIMIT}(calls[i]);
            console.log("L2 ProxyAdmin call gas", i, gasBefore - gasleft());
            if (!ok) assembly { revert(add(reason, 32), mload(reason)) }
        }
        _assertUpgrade(impls);
        require(_uint(VAULT, "totalProcessed()") == totalProcessed, "total processed changed");
        require(_uint(MESSENGER, "messageNonce()") == nonce, "messenger nonce changed");
        require(vm.load(MESSENGER, bytes32(uint256(204))) == sender, "messenger sender changed");
    }

    function _assertUpgrade(address[8] memory impls) internal view {
        address[8] memory proxies = _proxies();
        string[8] memory versions = _versions();
        for (uint256 i; i < 8; i++) {
            require(IProxyAdmin(ADMIN).getProxyImplementation(proxies[i]) == impls[i], "implementation mismatch");
            require(
                keccak256(bytes(ISemver(proxies[i]).version())) == keccak256(bytes(versions[i])), "version mismatch"
            );
        }
        _assertConfiguration();
    }

    function _assertConfiguration() internal view {
        for (uint256 i = 4; i < 8; i++) {
            uint256 flags = uint256(vm.load(_proxies()[i], bytes32(0))) >> (i == 4 ? 160 : 0);
            require(uint8(flags) == 1 && uint8(flags >> 8) == 0, "migration initializer mismatch");
        }
        require(_uint(MESSENGER, "otherMessenger()") == uint160(l1Messenger), "messenger counterpart mismatch");
        require(_uint(MESSENGER, "OTHER_MESSENGER()") == uint160(l1Messenger), "legacy messenger counterpart mismatch");
        require(_uint(BRIDGE, "messenger()") == uint160(MESSENGER), "bridge messenger mismatch");
        require(_uint(BRIDGE, "otherBridge()") == uint160(l1Bridge), "bridge counterpart mismatch");
        require(_uint(BRIDGE, "OTHER_BRIDGE()") == uint160(l1Bridge), "legacy bridge counterpart mismatch");
        require(_uint(ERC20_FACTORY, "bridge()") == uint160(BRIDGE), "ERC20 bridge mismatch");
        require(_uint(ERC20_FACTORY, "BRIDGE()") == uint160(BRIDGE), "legacy ERC20 bridge mismatch");
        require(_uint(ERC721_BRIDGE, "messenger()") == uint160(MESSENGER), "ERC721 messenger mismatch");
        require(_uint(ERC721_BRIDGE, "otherBridge()") == uint160(l1ERC721Bridge), "ERC721 counterpart mismatch");
        require(_uint(FACTORY, "bridge()") == uint160(factoryBridge), "factory bridge mismatch");
        require(_uint(FACTORY, "BRIDGE()") == uint160(factoryBridge), "legacy factory bridge mismatch");
        require(_uint(FACTORY, "remoteChainID()") == remoteChainId, "remote chain mismatch");
        require(_uint(FACTORY, "REMOTE_CHAIN_ID()") == remoteChainId, "legacy remote chain mismatch");
        require(_uint(VAULT, "recipient()") == uint160(vaultRecipient), "operator recipient mismatch");
        require(_uint(VAULT, "minWithdrawalAmount()") == vaultMinimum, "operator minimum mismatch");
        require(_uint(VAULT, "withdrawalNetwork()") == vaultNetwork, "operator network mismatch");
        require(_uint(VAULT, "RECIPIENT()") == uint160(vaultRecipient), "legacy operator recipient mismatch");
        require(_uint(VAULT, "MIN_WITHDRAWAL_AMOUNT()") == vaultMinimum, "legacy operator minimum mismatch");
        require(_uint(VAULT, "WITHDRAWAL_NETWORK()") == vaultNetwork, "legacy operator network mismatch");
        require(vm.load(VAULT, INITIALIZABLE_SLOT) == bytes32(uint256(1)), "operator initializer mismatch");
        require(_uint(EAS_PROXY, "getSchemaRegistry()") == uint160(REGISTRY), "EAS registry mismatch");
    }

    function _uint(address target, string memory signature) internal view returns (uint256) {
        (bool ok, bytes memory data) = target.staticcall(abi.encodeWithSignature(signature));
        require(ok, signature);
        return abi.decode(data, (uint256));
    }
}
