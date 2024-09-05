// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import {Setup, ERC20} from "./utils/Setup.sol";
import {GoldenBoyzCompounderStrategy} from "../Strategy.sol";

contract ManagementSetTest is Setup {
    address constant NO_MANAGEMENT_CALLER = address(6473875487);

    GoldenBoyzCompounderStrategy internal goldStrategy;

    function setUp() public virtual override {
        _setUp(BPT_WANT_ASSET);

        goldStrategy = GoldenBoyzCompounderStrategy(address(strategy));
    }

    function testSetSlippBalToWeth_revert() public {
        vm.prank(NO_MANAGEMENT_CALLER);
        vm.expectRevert("!management");
        goldStrategy.setSlippBalToWeth(1);

        vm.startPrank(management);
        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippBalToWeth(9_901);

        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippBalToWeth(9_599);
        vm.stopPrank();
    }

    function testSetSlippBalToWeth() public {
        vm.prank(management);
        goldStrategy.setSlippBalToWeth(9_850);
    }

    function testSetSlippAuraToWeth_revert() public {
        vm.prank(NO_MANAGEMENT_CALLER);
        vm.expectRevert("!management");
        goldStrategy.setSlippAuraToWeth(1);

        vm.startPrank(management);
        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippAuraToWeth(9_901);

        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippAuraToWeth(9_599);
        vm.stopPrank();
    }

    function testSetSlippAuraToWeth() public {
        vm.prank(management);
        goldStrategy.setSlippAuraToWeth(9_850);
    }

    function testSetSlippWethToYeth_revert() public {
        vm.prank(NO_MANAGEMENT_CALLER);
        vm.expectRevert("!management");
        goldStrategy.setSlippWethToYeth(1);

        vm.startPrank(management);
        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippWethToYeth(9_971);

        vm.expectRevert("Slippage out of bounds");
        goldStrategy.setSlippWethToYeth(9_890);
        vm.stopPrank();
    }

    function testSetSlippWethToYeth() public {
        vm.prank(management);
        goldStrategy.setSlippWethToYeth(9_950);
    }

    function testSetOracleWeightedPoolTimeWindow_revert() public {
        vm.prank(NO_MANAGEMENT_CALLER);
        vm.expectRevert("!management");
        goldStrategy.setOracleWeightedPoolTimeWindow(1);

        vm.startPrank(management);
        vm.expectRevert("Time window out of bounds");
        goldStrategy.setOracleWeightedPoolTimeWindow(30 minutes);

        vm.expectRevert("Time window out of bounds");
        goldStrategy.setOracleWeightedPoolTimeWindow(7 hours);
        vm.stopPrank();
    }

    function testSetOracleWeightedPoolTimeWindow() public {
        vm.prank(management);
        goldStrategy.setOracleWeightedPoolTimeWindow(2 hours);
    }

    function testSetCurveOracleTimeWindow_revert() public {
        vm.prank(NO_MANAGEMENT_CALLER);
        vm.expectRevert("!management");
        goldStrategy.setCurveOracleTimeWindow(1);

        vm.startPrank(management);
        vm.expectRevert("Time window out of bounds");
        goldStrategy.setCurveOracleTimeWindow(11 hours);

        vm.expectRevert("Time window out of bounds");
        goldStrategy.setCurveOracleTimeWindow(3 hours);
        vm.stopPrank();
    }

    function testSetCurveOracleTimeWindow() public {
        vm.prank(management);
        goldStrategy.setCurveOracleTimeWindow(28 hours);
    }
}
