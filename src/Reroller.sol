// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';

interface ISkipNFT {
  function setSkipNFT(bool skipNFT) external returns (bool);
  function getSkipNFT(address owner) external view returns (bool);
}

contract Reroller {
  using SafeERC20 for IERC20;

  constructor() {}

  function reroll(address dn404) external {
    if (!ISkipNFT(dn404).getSkipNFT(address(this))) ISkipNFT(dn404).setSkipNFT(true);
    IERC20(dn404).safeTransferFrom(msg.sender, address(this), 1);
    IERC20(dn404).safeTransfer(msg.sender, 1);
  }
}
