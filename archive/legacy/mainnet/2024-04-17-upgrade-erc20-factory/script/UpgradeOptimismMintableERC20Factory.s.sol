// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@base-contracts/script/universal/NestedMultisigBuilder.sol";

interface IProxyAdmin {
    function upgradeAndCall(address payable proxy, address implementation, bytes memory data) external payable;
}

interface IImpl {
    function initialize(address _bridge) external;
    function bridge() external returns (address);
}

bytes32 constant IMPLEMENTATION_KEY = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

contract UpgradeOptimismMintableERC20Factory is NestedMultisigBuilder {
    address public BRIDGE = vm.envAddress("BRIDGE");
    address public PROXY_ADMIN = vm.envAddress("PROXY_ADMIN");
    address public ERC20_FACTORY = vm.envAddress("ERC20_FACTORY");
    address public ERC20_FACTORY_IMPL = vm.envAddress("ERC20_FACTORY_IMPL");

    address internal NESTED_SAFE = vm.envAddress("NESTED_SAFE");

    function _postCheck(Vm.AccountAccess[] memory, SimulationPayload memory) internal override {
        address impl = address(uint160(uint256(vm.load(ERC20_FACTORY, IMPLEMENTATION_KEY))));
        if (impl != ERC20_FACTORY_IMPL) {
            revert("Implementation not correctly set");
        }

        address bridge_ = IImpl(ERC20_FACTORY).bridge();
        if (bridge_ != BRIDGE) {
            revert("Implementation not correctly initialized");
        }
    }

    function _buildCalls() internal view override returns (IMulticall3.Call3[] memory) {
        IMulticall3.Call3[] memory calls = new IMulticall3.Call3[](1);

        calls[0] = IMulticall3.Call3({
            target: address(PROXY_ADMIN),
            allowFailure: false,
            callData: abi.encodeCall(
                IProxyAdmin.upgradeAndCall,
                (payable(ERC20_FACTORY), ERC20_FACTORY_IMPL, abi.encodeCall(IImpl.initialize, (BRIDGE)))
            )
        });

        return calls;
    }

    function _ownerSafe() internal view override returns (address) {
        return NESTED_SAFE;
    }
}
