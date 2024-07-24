// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console} from '@std/Console.sol';
import {Script} from '@std/Script.sol';
import {Vm, VmSafe} from '@std/Vm.sol';

import {IERC20} from '@oz/token/ERC20/IERC20.sol';
import {IERC721} from '@oz/token/ERC721/IERC721.sol';
import {SafeERC20} from '@oz/token/ERC20/utils/SafeERC20.sol';
import {ProxyAdmin} from '@oz/proxy/transparent/ProxyAdmin.sol';
import {ERC1967Proxy} from '@oz/proxy/ERC1967/ERC1967Proxy.sol';

import {Reroller} from '../src/Reroller.sol';
import {RerollerV2, IRerollerV2DN404} from '../src/RerollerV2.sol';
import {RerollerV3, IRerollerV3DN404} from '../src/v3/RerollerV3.sol';
import {RerollerV3_1} from '../src/v3/RerollerV3_1.sol';

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
    address owner = vm.envAddress('OWNER');

    vm.createSelectFork('ethereum');

    // deploy

    vm.startBroadcast();

    RerollerV3 impl = new RerollerV3();
    RerollerV3 rerollerV3 = RerollerV3(
      address(new ERC1967Proxy(address(impl), abi.encodeCall(impl.initialize, (owner))))
    );

    vm.stopBroadcast();

    require(rerollerV3.owner() == owner, 'RerollerV3: owner mismatch');

    console.log('RerollerV3 deployed');
    console.log('owner :', owner);
    console.log('Impl  deployed at:', address(impl));
    console.log('Proxy deployed at:', address(rerollerV3));
  }
}

contract MigrateV3 is Script {
  function run() public {
    vm.createSelectFork('ethereum');

    IRerollerV3DN404 dn404 = IRerollerV3DN404(0xe591293151fFDadD5E06487087D9b0E2743de92E);
    IERC721 mirror = dn404.mirrorERC721();
    RerollerV3 rerollerV3 = RerollerV3(0x1753f8ef288301b7d38dD8DcC0cc10a3b2535bA0);
    address owner = rerollerV3.owner();

    vm.startBroadcast();

    RerollerV3_1 newImpl = new RerollerV3_1();
    rerollerV3.upgradeTo(address(newImpl));

    RerollerV3_1 rerollerV3_1 = RerollerV3_1(address(rerollerV3)); // wrap proxy to new version
    rerollerV3_1.manualSetSkipNFT(dn404, false);

    vm.stopBroadcast();

    console.log('RerollerV3 migrated to V3_1');
    console.log('newImpl deployed at:', address(newImpl));

    vm.startPrank(owner);

    vm.recordLogs();
    mirror.safeTransferFrom(owner, address(rerollerV3_1), 7072); // i have this

    uint256 mintedTokenId;

    {
      VmSafe.Log[] memory logs = vm.getRecordedLogs();
      VmSafe.Log memory last;

      for (uint256 i = 0; i < logs.length; i++) {
        if (
          logs[i].topics[0] == 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef && // must be Transfer
          logs[i].topics[1] == bytes32(0) && // must be zero (mint)
          logs[i].topics[2] == bytes32(uint256(uint160(address(owner)))) && // must be mint to owner
          logs[i].emitter == address(mirror)
        ) last = logs[i];
      }

      if (last.emitter == address(0)) revert('no Transfer event');
      mintedTokenId = uint256(last.topics[3]);
    }

    mirror.safeTransferFrom(owner, address(rerollerV3_1), mintedTokenId, abi.encode(mintedTokenId + 10));

    vm.stopPrank();
  }
}
