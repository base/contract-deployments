// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "@eth-optimism-bedrock/contracts/universal/ProxyAdmin.sol";
import "@base-contracts/src/Test.sol";

contract DeployTestProxy is Script {
    function run(address deployer, address safeToTest) public {
        // Deploy proxy admin contract
        vm.broadcast(deployer);
        ProxyAdmin proxyAdmin = new ProxyAdmin({
            _owner: deployer
        });
        require(proxyAdmin.owner() == deployer, "DeployTestProxy: proxyAdmin owner is incorrect");

        // Deploy an example proxy contract
        vm.broadcast(deployer);
        Proxy proxy = new Proxy({
            _admin: address(proxyAdmin)
        });
        vm.prank(address(0));
        require(proxy.admin() == address(proxyAdmin), "DeployTestProxy: admin is incorrect");

        // Deploy 2 implementations - 1 will be set initially, 1 will be used in test upgrade
        vm.broadcast(deployer);
        Test implementation = new Test();
        vm.broadcast(deployer);
        Test implementation2 = new Test();

        // Set implementation of proxy contract to first implementation
        vm.broadcast(deployer);
        proxyAdmin.upgrade({
            _proxy: payable(proxy),
            _implementation: address(implementation)
        });
        require(
            proxyAdmin.getProxyImplementation(address(proxy)) == address(implementation),
            "DeployTestProxy: implementation did not get set"
        );

        // Set safe we are testing to be the proxy admin owner
        vm.broadcast(deployer);
        proxyAdmin.transferOwnership(safeToTest);
        require(proxyAdmin.owner() == safeToTest, "DeployTestProxy: proxyAdmin owner did not transfer correctly");

        console.log("DeployTestProxy: Deployed Addresses");
        console.log("ProxyAdmin: ", address(proxyAdmin));
        console.log("Proxy: ", address(proxy));
        console.log("Implementation: ", address(implementation));
        console.log("Implementation2: ", address(implementation2));
    }
}