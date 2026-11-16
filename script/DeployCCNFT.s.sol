// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {BUSD} from "../src/BUSD.sol";
import {CCNFT} from "../src/CCNFT.sol";

contract DeployCCNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address busdAddress = vm.envAddress("BUSD_ADDRESS");

        require(busdAddress != address(0), "Invalid BUSD address");

        vm.startBroadcast(deployerPrivateKey);

        BUSD busd = BUSD(busdAddress);

        CCNFT ccnft = new CCNFT();

        // Configurar contratos
        ccnft.setFundsToken(busdAddress);
        ccnft.setFundsCollector(deployer);
        ccnft.setFeesCollector(deployer);

        // Configuracion economica
        ccnft.setProfitToPay(500);
        ccnft.setBuyFee(250);
        ccnft.setTradeFee(300);

        // Configuracion de emision
        ccnft.setMaxValueToRaise(1_000_000 ether);
        ccnft.setMaxBatchCount(5);

        ccnft.addValidValues(100 ether);
        ccnft.addValidValues(500 ether);
        ccnft.addValidValues(1_000 ether);

        // Habilitar operaciones
        ccnft.setCanBuy(true);
        ccnft.setCanClaim(true);
        ccnft.setCanTrade(true);

        // Autorizar a CCNFT a retirar BUSD del fondo
        bool approved = busd.approve(address(ccnft), type(uint256).max);

        require(approved, "BUSD approval failed");

        vm.stopBroadcast();

        console2.log("BUSD address:", busdAddress);
        console2.log("CCNFT deployed at:", address(ccnft));
    }
}
