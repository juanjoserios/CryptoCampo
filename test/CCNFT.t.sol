// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {BUSD} from "../src/BUSD.sol";
import {CCNFT} from "../src/CCNFT.sol";

// Definición del contrato de prueba CCNFTTest que hereda de Test.
// Declaración de direcciones y dos instancias de contratos (BUSD y CCNFT).
contract CCNFTTest is Test {
    address deployer;
    address c1;
    address c2;
    address funds;
    address fees;
    BUSD busd;
    CCNFT ccnft;

    // Ejecución antes de cada prueba.
    // Inicializar las direcciones y desplgar las instancias de BUSD y CCNFT.
    function setUp() public {
        deployer = makeAddr("deployer");
        c1 = makeAddr("c1");
        c2 = makeAddr("c2");
        funds = makeAddr("funds");
        fees = makeAddr("fees");

        vm.startPrank(deployer);

        busd = new BUSD();
        ccnft = new CCNFT();

        ccnft.setFundsToken(address(busd));
        ccnft.setFundsCollector(funds);
        ccnft.setFeesCollector(fees);

        vm.stopPrank();
    }

    // Prueba de "setFundsCollector" del contrato CCNFT.
    // Llamar al método y despues verificar que el valor se haya establecido correctamente.
    function testSetFundsCollector() public {
        vm.prank(deployer);

        ccnft.setFundsCollector(c1);

        assertEq(ccnft.fundsCollector(), c1);
    }

    // Prueba de "setFeesCollector" del contrato CCNFT
    // Verificar que el valor se haya establecido correctamente.
    function testSetFeesCollector() public {
        vm.prank(deployer);

        ccnft.setFeesCollector(c2);

        assertEq(ccnft.feesCollector(), c2);
    }

    // Prueba de "setProfitToPay" del contrato CCNFT
    // Verificar que el valor se haya establecido correctamente.
    function testSetProfitToPay() public {
        vm.startPrank(deployer);

        ccnft.setProfitToPay(500);
        assertEq(ccnft.profitToPay(), 500);

        ccnft.setProfitToPay(1000);
        assertEq(ccnft.profitToPay(), 1000);

        vm.stopPrank();
    }

    // Prueba de "setCanBuy" primero estableciéndolo en true y verificando que se establezca correctamente.
    // Despues establecerlo en false verificando nuevamente.
    function testSetCanBuy() public {
        vm.startPrank(deployer);

        ccnft.setCanBuy(true);
        assertTrue(ccnft.canBuy());

        ccnft.setCanBuy(false);
        assertFalse(ccnft.canBuy());

        vm.stopPrank();
    }

    // Prueba de método "setCanTrade". Similar a "testSetCanBuy".
    function testSetCanTrade() public {
        vm.startPrank(deployer);

        ccnft.setCanTrade(true);
        assertTrue(ccnft.canTrade());

        ccnft.setCanTrade(false);
        assertFalse(ccnft.canTrade());

        vm.stopPrank();
    }

    // Prueba de método "setCanClaim". Similar a "testSetCanBuy".
    function testSetCanClaim() public {
        vm.startPrank(deployer);

        ccnft.setCanClaim(true);
        assertTrue(ccnft.canClaim());

        ccnft.setCanClaim(false);
        assertFalse(ccnft.canClaim());

        vm.stopPrank();
    }

    // Prueba de "setMaxValueToRaise" con diferentes valores.
    // Verifica que se establezcan correctamente.
    function testSetMaxValueToRaise() public {
        vm.startPrank(deployer);

        ccnft.setMaxValueToRaise(1_000 * 10 ** 18);
        assertEq(ccnft.maxValueToRaise(), 1_000 * 10 ** 18);

        ccnft.setMaxValueToRaise(2_000 * 10 ** 18);
        assertEq(ccnft.maxValueToRaise(), 2_000 * 10 ** 18);

        vm.stopPrank();
    }

    // Prueba de "addValidValues" añadiendo diferentes valores.
    // Verificar que se hayan añadido correctamente.
    function testAddValidValues() public {
        uint256 value1 = 100 * 10 ** 18;
        uint256 value2 = 500 * 10 ** 18;
        uint256 value3 = 250 * 10 ** 18;

        vm.startPrank(deployer);

        ccnft.addValidValues(value1);
        ccnft.addValidValues(value2);

        vm.stopPrank();

        assertTrue(ccnft.validValues(value1));
        assertTrue(ccnft.validValues(value2));
        assertFalse(ccnft.validValues(value3));
    }

    // Prueba de "setMaxBatchCount".
    // Verifica que el valor se haya establecido correctamente.
    function testSetMaxBatchCount() public {
        vm.startPrank(deployer);

        ccnft.setMaxBatchCount(5);
        assertEq(ccnft.maxBatchCount(), 5);

        ccnft.setMaxBatchCount(10);
        assertEq(ccnft.maxBatchCount(), 10);

        vm.stopPrank();
    }

    // Prueba de "setBuyFee".
    // Verificar que el valor se haya establecido correctamente.
    function testSetBuyFee() public {
        vm.startPrank(deployer);

        ccnft.setBuyFee(250);
        assertEq(ccnft.buyFee(), 250);

        ccnft.setBuyFee(500);
        assertEq(ccnft.buyFee(), 500);

        vm.stopPrank();
    }

    // Prueba de "setTradeFee".
    // Verificar que el valor se haya establecido correctamente.
    function testSetTradeFee() public {
        vm.startPrank(deployer);

        ccnft.setTradeFee(300);
        assertEq(ccnft.tradeFee(), 300);

        ccnft.setTradeFee(600);
        assertEq(ccnft.tradeFee(), 600);

        vm.stopPrank();
    }

    // Prueba de que no se pueda comerciar cuando canTrade es false.
    // Verificar que se lance un error esperado.
    function testCannotTradeWhenCanTradeIsFalse() public {
        vm.prank(deployer);
        ccnft.setCanTrade(false);

        vm.expectRevert("Trading is disabled");

        ccnft.trade(1);
    }

    // Prueba que no se pueda comerciar con un token que no existe, incluso si canTrade es true.
    // Verificar que se lance un error esperado.
    function testCannotTradeWhenTokenDoesNotExist() public {
        vm.prank(deployer);
        ccnft.setCanTrade(true);

        vm.expectRevert("Token does not exist");

        ccnft.trade(1);
    }

    function testBuy() public {
        uint256 nftValue = 100 * 10 ** 18;
        uint256 amount = 2;
        uint256 purchaseValue = nftValue * amount;
        uint256 feeAmount = (purchaseValue * 250) / 10000;
        uint256 totalCost = purchaseValue + feeAmount;

        vm.startPrank(deployer);

        ccnft.setCanBuy(true);
        ccnft.addValidValues(nftValue);
        ccnft.setMaxBatchCount(5);
        ccnft.setMaxValueToRaise(purchaseValue);
        ccnft.setBuyFee(250);

        busd.transfer(c1, totalCost);

        vm.stopPrank();

        vm.prank(c1);
        busd.approve(address(ccnft), totalCost);

        vm.prank(c1);
        ccnft.buy(nftValue, amount);

        assertEq(ccnft.balanceOf(c1), 2);
        assertEq(ccnft.totalSupply(), 2);

        assertEq(ccnft.ownerOf(1), c1);
        assertEq(ccnft.ownerOf(2), c1);

        assertEq(ccnft.values(1), nftValue);
        assertEq(ccnft.values(2), nftValue);

        assertEq(ccnft.totalValue(), purchaseValue);

        assertEq(busd.balanceOf(funds), purchaseValue);
        assertEq(busd.balanceOf(fees), feeAmount);
        assertEq(busd.balanceOf(c1), 0);
    }

    function testClaim() public {
        uint256 nftValue = 100 * 10 ** 18;
        uint256 amount = 2;
        uint256 purchaseValue = nftValue * amount;

        uint256 buyFeeAmount = (purchaseValue * 250) / 10000;
        uint256 totalCost = purchaseValue + buyFeeAmount;

        uint256 profitAmount = (purchaseValue * 500) / 10000;
        uint256 claimAmount = purchaseValue + profitAmount;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        vm.startPrank(deployer);

        ccnft.setCanBuy(true);
        ccnft.setCanClaim(true);
        ccnft.addValidValues(nftValue);
        ccnft.setMaxBatchCount(5);
        ccnft.setMaxValueToRaise(purchaseValue);
        ccnft.setBuyFee(250);
        ccnft.setProfitToPay(500);

        busd.transfer(c1, totalCost);

        vm.stopPrank();

        vm.prank(c1);
        busd.approve(address(ccnft), totalCost);

        vm.prank(c1);
        ccnft.buy(nftValue, amount);

        vm.prank(deployer);
        busd.transfer(funds, profitAmount);

        vm.prank(funds);
        busd.approve(address(ccnft), claimAmount);

        vm.prank(c1);
        ccnft.claim(tokenIds);

        assertEq(ccnft.balanceOf(c1), 0);
        assertEq(ccnft.totalSupply(), 0);

        assertEq(ccnft.totalValue(), 0);

        assertEq(ccnft.values(1), 0);
        assertEq(ccnft.values(2), 0);

        assertEq(busd.balanceOf(funds), 0);
        assertEq(busd.balanceOf(c1), claimAmount);
        assertEq(busd.balanceOf(fees), buyFeeAmount);
    }

    function testTrade() public {
        uint256 nftValue = 100 * 10 ** 18;
        uint256 purchaseValue = nftValue;

        uint256 buyFeeAmount = (purchaseValue * 250) / 10000;
        uint256 initialCost = purchaseValue + buyFeeAmount;

        uint256 salePrice = 150 * 10 ** 18;
        uint256 tradeFeeAmount = (salePrice * 300) / 10000;
        uint256 tradeCost = salePrice + tradeFeeAmount;

        vm.startPrank(deployer);

        ccnft.setCanBuy(true);
        ccnft.setCanTrade(true);
        ccnft.addValidValues(nftValue);
        ccnft.setMaxBatchCount(5);
        ccnft.setMaxValueToRaise(purchaseValue);
        ccnft.setBuyFee(250);
        ccnft.setTradeFee(300);

        busd.transfer(c1, initialCost);
        busd.transfer(c2, tradeCost);

        vm.stopPrank();

        vm.prank(c1);
        busd.approve(address(ccnft), initialCost);

        vm.prank(c1);
        ccnft.buy(nftValue, 1);

        vm.prank(c1);
        ccnft.putOnSale(1, salePrice);

        vm.prank(c2);
        busd.approve(address(ccnft), tradeCost);

        vm.prank(c2);
        ccnft.trade(1);

        assertEq(ccnft.ownerOf(1), c2);

        assertEq(ccnft.balanceOf(c1), 0);
        assertEq(ccnft.balanceOf(c2), 1);

        assertEq(ccnft.values(1), nftValue);
        assertEq(ccnft.totalValue(), purchaseValue);

        (bool onSale, uint256 price) = ccnft.tokensOnSale(1);

        assertFalse(onSale);
        assertEq(price, 0);

        assertEq(busd.balanceOf(funds), purchaseValue);
        assertEq(busd.balanceOf(c1), salePrice);
        assertEq(busd.balanceOf(fees), buyFeeAmount + tradeFeeAmount);
        assertEq(busd.balanceOf(c2), 0);
    }
}
