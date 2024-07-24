// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {ERC721Holder} from '@oz/token/ERC721/utils/ERC721Holder.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';

import {Ownable} from '@oz/access/Ownable.sol';
import {IRerollerV3DN404} from './RerollerV3.sol';

contract TempVault is Ownable, ERC721Holder {
  using SafeERC20 for IRerollerV3DN404;

  event AssetInitialized(IRerollerV3DN404 asset);
  event AssetDeinitialized(IRerollerV3DN404 asset);

  error TempVault__NotAllowed(IRerollerV3DN404 asset);
  error TempVault__AlreadyAllowed(IRerollerV3DN404 asset);

  constructor() Ownable() {}

  function initNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    IERC721 mirror = dn404.mirrorERC721();
    address owner_ = owner();

    dn404.setSkipNFT(false);
    mirror.setApprovalForAll(owner_, true);
    dn404.forceApprove(owner_, type(uint256).max);

    emit AssetInitialized(dn404);
  }

  function deinitNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    IERC721 mirror = dn404.mirrorERC721();
    address owner_ = owner();

    mirror.setApprovalForAll(owner_, false);
    dn404.forceApprove(owner_, 0);

    emit AssetDeinitialized(dn404);
  }
}
