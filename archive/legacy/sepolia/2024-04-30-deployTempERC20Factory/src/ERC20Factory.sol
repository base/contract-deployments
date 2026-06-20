// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {OptimismMintableERC20Factory} from "@eth-optimism-bedrock/src/universal/OptimismMintableERC20Factory.sol";

contract ERC20Factory is OptimismMintableERC20Factory {
  constructor() {
    initialize({ _bridge: address(0x4200000000000000000000000000000000000010 ) });
  }
}