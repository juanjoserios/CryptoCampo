// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {BUSD} from "../src/BUSD.sol";

contract BUSDTest is Test {
    BUSD busd;

    uint256 constant INITIAL_SUPPLY = 10_000_000 * 10 ** 18;

    function setUp() public {
        busd = new BUSD();
    }

    function testName() public view {
        assertEq(busd.name(), "BUSD");
    }

    function testSymbol() public view {
        assertEq(busd.symbol(), "BUSD");
    }

    function testDecimals() public view {
        assertEq(busd.decimals(), 18);
    }

    function testInitialTotalSupply() public view {
        assertEq(busd.totalSupply(), INITIAL_SUPPLY);
    }

    function testInitialBalanceOfDeployer() public view {
        assertEq(busd.balanceOf(address(this)), INITIAL_SUPPLY);
    }
}
