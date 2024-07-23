// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {ERC721Holder} from '@oz/token/ERC721/utils/ERC721Holder.sol';
import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';

import {Ownable} from '@oz/access/Ownable.sol';
import {Pausable} from '@oz/security/Pausable.sol';
import {OwnableUpgradeable} from '@ozu/access/OwnableUpgradeable.sol';
import {UUPSUpgradeable} from '@ozu/proxy/utils/UUPSUpgradeable.sol';

import {ERC20} from '@solady/tokens/ERC20.sol';

interface IRerollerV3DN404 is IERC20 {
  function setSkipNFT(bool skipNFT) external returns (bool);
  function getSkipNFT(address owner) external view returns (bool);
  function mirrorERC721() external returns (IERC721);
}

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

contract RerollKarma is ERC20, Ownable, Pausable {
  constructor() Ownable() Pausable() {}

  function name() public pure override returns (string memory) {
    return 'Reroll Karma';
  }

  function symbol() public pure override returns (string memory) {
    return 'ROLL';
  }

  function decimals() public pure override returns (uint8) {
    return 6;
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyOwner {
    _burn(from, amount);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}

contract RerollerV3 is ERC721Holder, OwnableUpgradeable, UUPSUpgradeable {
  using SafeERC20 for IRerollerV3DN404;

  uint256 constant LOOP_LIMIT = 100;

  error RerollerV3__TempVaultSanityCheckFailed(string reason);
  error RerollerV3__LoopLimitExceeded();
  error RerollerV3__InvalidAddress(string typ);

  TempVault public tempVault;
  RerollKarma public rerollKarma;

  mapping(IRerollerV3DN404 dn404 => bool initialized) internal _allowed;
  mapping(IERC721 mirror => IRerollerV3DN404 dn404) internal _mirrorToDn404;

  /// @notice UUPS upgrade authorization
  /// @dev DO NOT REMOVE THIS FUNCTION UNLESS YOU KNOW WHAT YOU ARE DOING
  function _authorizeUpgrade(address) internal override onlyOwner {}

  constructor() {
    _disableInitializers();
  }

  function initialize(address owner) external initializer {
    if (owner == address(0)) revert RerollerV3__InvalidAddress('owner');

    __Ownable_init();
    _transferOwnership(owner);
    __UUPSUpgradeable_init();

    tempVault = new TempVault();
    rerollKarma = new RerollKarma();
  }

  function allowed(IRerollerV3DN404 asset) external view returns (bool) {
    return _allowed[asset];
  }

  function mirrorToDn404(IERC721 mirror) external view returns (IRerollerV3DN404) {
    return _mirrorToDn404[mirror];
  }

  function initNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    if (!dn404.getSkipNFT(address(this))) dn404.setSkipNFT(true);
    tempVault.initNewAsset(dn404);

    _allowed[dn404] = true;
    _mirrorToDn404[dn404.mirrorERC721()] = dn404;
  }

  function deinitNewAsset(IRerollerV3DN404 dn404) external onlyOwner {
    tempVault.deinitNewAsset(dn404);

    _allowed[dn404] = false;
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

    while (true) {
      dn404.safeTransferFrom(address(tempVault), address(this), 1);
      dn404.safeTransfer(address(tempVault), 1);

      try mirror.ownerOf(targetTokenId) returns (address owner) {
        if (address(tempVault) == owner) break;
      } catch {}

      karma = karma + 1;
      if (karma > LOOP_LIMIT) revert RerollerV3__LoopLimitExceeded();
    }

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

    _rerollUntil(dn404, mirror, from, tokenId, abi.decode(data, (uint256)));

    return super.onERC721Received(operator, from, tokenId, data);
  }
}
