// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {BUSD} from "../src/BUSD.sol";
import {CCNFT} from "../src/CCNFT.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Desplegar los contratos
        BUSD busd = new BUSD();
        CCNFT ccnft = new CCNFT();

        // Configurar los contratos
        ccnft.setFundsToken(address(busd));
        ccnft.setFundsCollector(deployer);
        ccnft.setFeesCollector(deployer);

        // Configuración económica
        ccnft.setProfitToPay(500);
        ccnft.setBuyFee(250);
        ccnft.setTradeFee(300);

        // Configuración de emisión
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
    }
}
