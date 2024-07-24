// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {ERC721Holder} from '@oz/token/ERC721/utils/ERC721Holder.sol';
import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';

import {OwnableUpgradeable} from '@ozu/access/OwnableUpgradeable.sol';
import {UUPSUpgradeable} from '@ozu/proxy/utils/UUPSUpgradeable.sol';

import {IRerollerV3DN404} from './RerollerV3.sol';

interface ITempVault {
  function initNewAsset(IRerollerV3DN404 dn404) external;
  function deinitNewAsset(IRerollerV3DN404 dn404) external;
}

interface IRerollKarma is IERC20 {
  function mint(address to, uint256 amount) external;
}

contract RerollerV3_1 is ERC721Holder, OwnableUpgradeable, UUPSUpgradeable {
  using SafeERC20 for IRerollerV3DN404;

  uint256 constant LOOP_LIMIT = 100;

  error RerollerV3__TempVaultSanityCheckFailed(string reason);
  error RerollerV3__LoopLimitExceeded();
  error RerollerV3__InvalidAddress(string typ);

  ITempVault public tempVault;
  IRerollKarma public rerollKarma;

  mapping(IRerollerV3DN404 dn404 => bool initialized) internal _allowed;
  mapping(IERC721 mirror => IRerollerV3DN404 dn404) internal _mirrorToDn404;

  /// @notice UUPS upgrade authorization
  /// @dev DO NOT REMOVE THIS FUNCTION UNLESS YOU KNOW WHAT YOU ARE DOING
  function _authorizeUpgrade(address) internal override onlyOwner {}

  constructor() {
    _disableInitializers();
  }

  function allowed(IRerollerV3DN404 asset) external view returns (bool) {
    return _allowed[asset];
  }

  function mirrorToDn404(IERC721 mirror) external view returns (IRerollerV3DN404) {
    return _mirrorToDn404[mirror];
  }

  function initNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    tempVault.initNewAsset(dn404);

    _allowed[dn404] = true;
    _mirrorToDn404[dn404.mirrorERC721()] = dn404;
  }

  function deinitNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    tempVault.deinitNewAsset(dn404);

    _allowed[dn404] = false;
  }

  function manualSetSkipNFT(IRerollerV3DN404 dn404, bool skipNFT) external onlyOwner {
    dn404.setSkipNFT(skipNFT);
  }

  function _reroll(IRerollerV3DN404 dn404, address from) internal {
    dn404.safeTransfer(from, 0.5 ether);
    dn404.safeTransfer(from, 0.5 ether);

    rerollKarma.mint(from, 1e6);
  }

  function _rerollUntil(
    IRerollerV3DN404 dn404,
    IERC721 mirror,
    address from,
    uint256 tokenId,
    uint256 targetTokenId
  ) internal {
    // pre-validation
    if (dn404.balanceOf(address(tempVault)) != 0) revert RerollerV3__TempVaultSanityCheckFailed('!pre.erc20.balance');

    // send mirror(nft) to temp vault
    mirror.safeTransferFrom(address(this), address(tempVault), tokenId);

    // reroll until target nft is received
    uint256 karma = 0;

    dn404.setSkipNFT(true);

    while (true) {
      dn404.safeTransferFrom(address(tempVault), address(this), 1);
      dn404.safeTransfer(address(tempVault), 1);

      try mirror.ownerOf(targetTokenId) returns (address owner) {
        if (address(tempVault) == owner) break;
      } catch {}

      karma = karma + 1;
      if (karma > LOOP_LIMIT) revert RerollerV3__LoopLimitExceeded();
    }

    dn404.setSkipNFT(false);

    // send target nft to sender
    mirror.safeTransferFrom(address(tempVault), from, targetTokenId);

    // mint karma
    rerollKarma.mint(from, karma * 1e6);

    // post-validation
    address targetTokenOwner = mirror.ownerOf(targetTokenId);
    if (targetTokenOwner == address(tempVault) || targetTokenOwner == address(this))
      revert RerollerV3__TempVaultSanityCheckFailed('!post.erc721.transfer');
    if (dn404.balanceOf(address(tempVault)) != 0) revert RerollerV3__TempVaultSanityCheckFailed('!post.erc20.balance');
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) public override returns (bytes4) {
    IERC721 mirror = IERC721(_msgSender());
    IRerollerV3DN404 dn404 = _mirrorToDn404[mirror];
    if (!_allowed[dn404]) revert RerollerV3__TempVaultSanityCheckFailed('not allowed');

    if (data.length == 0) _reroll(dn404, from);
    else _rerollUntil(dn404, mirror, from, tokenId, abi.decode(data, (uint256)));

    return super.onERC721Received(operator, from, tokenId, data);
  }
}
