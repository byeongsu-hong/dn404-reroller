// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Ownable} from '@oz/access/Ownable.sol';
import {Pausable} from '@oz/security/Pausable.sol';

import {ERC20} from '@solady/tokens/ERC20.sol';

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
