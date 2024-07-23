// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';

interface IRerollerV2DN404 is IERC20 {
  function setSkipNFT(bool skipNFT) external returns (bool);
  function getSkipNFT(address owner) external view returns (bool);
  function mirrorERC721() external returns (IERC721);
}

contract RerollerV2 {
  using SafeERC20 for IRerollerV2DN404;

  constructor() {}

  function reroll(IRerollerV2DN404 dn404) external {
    if (!dn404.getSkipNFT(address(this))) dn404.setSkipNFT(true);
    dn404.safeTransferFrom(msg.sender, address(this), 1);
    dn404.safeTransfer(msg.sender, 1);
  }

  function rerollUntil(IRerollerV2DN404 dn404, uint256 tokenId) external {
    if (!dn404.getSkipNFT(address(this))) dn404.setSkipNFT(true);

    IERC721 mirror = dn404.mirrorERC721();

    while (true) {
      dn404.safeTransferFrom(msg.sender, address(this), 1);
      dn404.safeTransfer(msg.sender, 1);
      try mirror.ownerOf(tokenId) returns (address owner) {
        if (msg.sender == owner) break;
      } catch {}
    }
  }
}
