// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console} from "@std/Console.sol";
import {Script} from "@std/Script.sol";
import {Vm} from "@std/Vm.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

import {Reroller} from "../src/Reroller.sol";
import {RerollerV2, IRerollerV2DN404} from "../src/RerollerV2.sol";

address constant morse = 0xe591293151fFDadD5E06487087D9b0E2743de92E;

contract Deploy is Script {
    using SafeERC20 for IERC20;

    function run() public {
        vm.createSelectFork("ethereum");

        vm.broadcast();
        Reroller reroller = new Reroller(IERC20(morse));

        console.log("Reroller deployed at:", address(reroller));
    }
}

contract DeployV2 is Script {
    using SafeERC20 for IERC20;

    function run() public {
        vm.createSelectFork("ethereum");

        vm.broadcast();
        RerollerV2 rerollerV2 = new RerollerV2(IRerollerV2DN404(morse));

        console.log("RerollerV2 deployed at:", address(rerollerV2));
    }
}
