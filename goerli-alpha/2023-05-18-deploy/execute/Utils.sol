pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract Utils is Script {
    using stdJson for string;

    struct DeployBedrockConfig {
        address batchSenderAddress;
        address controller;
        address deployerAddress;
        address finalSystemOwner;
        uint256 finalizationPeriodSeconds;
        uint256 gasPriceOracleOverhead;
        uint256 gasPriceOracleScalar;
        uint256 l2BlockTime;
        uint64 l2GenesisBlockGasLimit;
        address l2OutputOracleChallenger;
        address l2OutputOracleProposer;
        uint256 l2OutputOracleStartingBlockNumber;
        uint256 l2OutputOracleSubmissionInterval;
        address p2pSequencerAddress;
        address proxyAdminOwner;
    }

    struct AddressesConfig {
        address AddressManager;
        uint BlockNumber;
        uint BlockTimestamp;
        address L1ContractsOwner;
        address L1CrossDomainMessengerImpl;
        address L1CrossDomainMessengerProxy;
        address L1ERC721BridgeImpl;
        address L1ERC721BridgeProxy;
        address L1StandardBridgeImpl;
        address L1StandardBridgeProxy;
        address L2ContractsOwner;
        address L2OutputOracleImpl;
        address L2OutputOracleProxy;
        address OptimismMintableERC20FactoryImpl;
        address OptimismMintableERC20FactoryProxy;
        address OptimismPortalImpl;
        address OptimismPortalProxy;
        address PortalSenderImpl;
        address ProxyAdmin;
        address SystemConfigImpl;
        address SystemConfigProxy;
        address SystemDictatorImpl;
        address SystemDictatorProxy;
    }

    function getDeployBedrockConfig(string memory network) external view returns(DeployBedrockConfig memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "deployed/foundry-config.json");
        string memory json = vm.readFile(path);
        bytes memory deployBedrockConfigRaw = json.parseRaw(".deployConfig");
        return abi.decode(deployBedrockConfigRaw, (DeployBedrockConfig));
    }

    function readAddressesFile(string memory network) external view returns (AddressesConfig memory) {
        string memory root = vm.projectRoot();
        string memory addressPath = string.concat(root, "deployed/addresses.json");
        string memory addressJson = vm.readFile(addressPath);
        bytes memory addressRaw = vm.parseJson(addressJson);
        return abi.decode(addressRaw, (AddressesConfig));
    }

    function writeAddressesFile(string memory network, AddressesConfig memory cfg) external {
        string memory json= "";

        // Proxy contract addresses
        vm.serializeAddress(json, "ProxyAdmin", cfg.ProxyAdmin);
        vm.serializeAddress(json, "AddressManager", cfg.AddressManager);
        vm.serializeAddress(json, "L1StandardBridgeProxy", cfg.L1StandardBridgeProxy);
        vm.serializeAddress(json, "L2OutputOracleProxy", cfg.L2OutputOracleProxy);
        vm.serializeAddress(json, "L1CrossDomainMessengerProxy", cfg.L1CrossDomainMessengerProxy);
        vm.serializeAddress(json, "OptimismPortalProxy", cfg.OptimismPortalProxy);
        vm.serializeAddress(json, "OptimismMintableERC20FactoryProxy", cfg.OptimismMintableERC20FactoryProxy);
        vm.serializeAddress(json, "L1ERC721BridgeProxy", cfg.L1ERC721BridgeProxy);
        vm.serializeAddress(json, "SystemConfigProxy", cfg.SystemConfigProxy);
        vm.serializeAddress(json, "SystemDictatorProxy", cfg.SystemDictatorProxy);

        // Implementation contract addresses
        vm.serializeAddress(json, "L1CrossDomainMessengerImpl", cfg.L1CrossDomainMessengerImpl);
        vm.serializeAddress(json, "L1StandardBridgeImpl", cfg.L1StandardBridgeImpl);
        vm.serializeAddress(json, "L2OutputOracleImpl", cfg.L2OutputOracleImpl);
        vm.serializeAddress(json, "OptimismPortalImpl", cfg.OptimismPortalImpl);
        vm.serializeAddress(json, "PortalSenderImpl", cfg.PortalSenderImpl);
        vm.serializeAddress(json, "L1ERC721BridgeImpl", cfg.L1ERC721BridgeImpl);
        vm.serializeAddress(json, "SystemConfigImpl", cfg.SystemConfigImpl);
        vm.serializeAddress(json, "SystemDictatorImpl", cfg.SystemDictatorImpl);
        vm.serializeAddress(json, "OptimismMintableERC20FactoryImpl", cfg.OptimismMintableERC20FactoryImpl);

        // Controller addresses
        vm.serializeAddress(json, "L1ContractsOwner", cfg.L1ContractsOwner);
        vm.serializeAddress(json, "L2ContractsOwner", cfg.L2ContractsOwner);

        vm.serializeUint(json, "BlockNumber", cfg.BlockNumber);
        string memory finalJson = vm.serializeUint(json, "BlockTimestamp", cfg.BlockTimestamp);

        finalJson.write(string.concat("deployed/unsorted.json"));
    }
}
