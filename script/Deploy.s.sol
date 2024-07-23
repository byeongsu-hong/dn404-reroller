// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console} from '@std/Console.sol';
import {Script} from '@std/Script.sol';
import {Vm} from '@std/Vm.sol';

import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';
import {ProxyAdmin} from '@oz/proxy/transparent/ProxyAdmin.sol';
import {ERC1967Proxy} from '@oz/proxy/ERC1967/ERC1967Proxy.sol';

import {Reroller} from '../src/Reroller.sol';
import {RerollerV2, IRerollerV2DN404} from '../src/RerollerV2.sol';
import {RerollerV3, IRerollerV3DN404} from '../src/RerollerV3.sol';

contract Deploy is Script {
  function run() public {
    vm.createSelectFork('ethereum');

    vm.broadcast();
    Reroller reroller = new Reroller();

    console.log('Reroller deployed at:', address(reroller));
  }
}

contract DeployV2 is Script {
  function run() public {
    vm.createSelectFork('ethereum');

    vm.broadcast();
    RerollerV2 rerollerV2 = new RerollerV2();

    console.log('RerollerV2 deployed at:', address(rerollerV2));
  }
}

contract DeployV3 is Script {
  function run() public {
    vm.createSelectFork('ethereum');

    // deploy

    address owner = 0xf587eD06FBAc43b8333B6A50E9079b73fD579189;
    RerollerV3 impl = RerollerV3(0x1FF8B89070D4dd359747f682C42081C88804F579);

    vm.startBroadcast();

    RerollerV3 rerollerV3 = RerollerV3(
      address(new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, (owner))))
    );

    vm.stopBroadcast();

    console.log('RerollerV3 deployed');
    console.log('owner :', owner);
    console.log('Impl  deployed at:', address(impl));
    console.log('Proxy deployed at:', address(rerollerV3));
  }
}
