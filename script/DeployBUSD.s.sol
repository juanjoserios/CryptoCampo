// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {BUSD} from "../src/BUSD.sol";

contract DeployBUSD is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        BUSD busd = new BUSD();

        vm.stopBroadcast();

        console2.log("BUSD deployed at:", address(busd));
    }
}
