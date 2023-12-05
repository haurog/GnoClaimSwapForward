// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console2 } from "forge-std/Test.sol";
import { ClaimForward } from "../src/ClaimForward.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimForwardTest is Test {
	uint256 gnosisFork;
	ClaimForward public claimForward;

	address claimAddress = 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1;
	address gnoTokenAddress = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
	address wxdaiTokenAddress = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
    address eureTokenAddress = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
	address destinationAddress = 0xAeC36E243159FC601140Db90da6961133630f15D; // Gnosis pay wallet

	function setUp() public {
		// gnosisFork = vm.createFork("https://rpc.gnosis.gateway.fm");
		gnosisFork = vm.createFork("http://192.168.1.123:8545");
		vm.selectFork(gnosisFork);
		claimForward = new ClaimForward();
	}

	function test_claimWithdrawal() public {
	    uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
        uint256 amountBefore = IERC20(gnoTokenAddress).balanceOf(claimAddress);
        claimForward.claimWithdrawal(claimAddress);
        uint256 amountAfter = IERC20(gnoTokenAddress).balanceOf(claimAddress);
	    assertEq(amountAfter-amountBefore, withdrawableAmount);
	}

	function test_claimAndForward() public {
		address claimForwardAddress = address(claimForward);

		uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
        emit log_named_uint("withdrawableAmount", withdrawableAmount);
		uint256 amountBefore = IERC20(gnoTokenAddress).balanceOf(destinationAddress);

		// Set allowance
		vm.startPrank(claimAddress);
		IERC20(gnoTokenAddress).approve(claimForwardAddress, withdrawableAmount);
		uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
			claimAddress,
			claimForwardAddress
		);
		vm.stopPrank();

		assertEq(withdrawableAmount, allowanceAmount);

		claimForward.claimAndForward(claimAddress);

		uint256 amountAfter = IERC20(gnoTokenAddress).balanceOf(destinationAddress);
		uint difference = amountAfter - amountBefore;
		assertEq(difference, withdrawableAmount);
	}

	function test_claimandSwap() public {
		address claimForwardAddress = address(claimForward);
        uint256 wxdaiAmountBefore = IERC20(wxdaiTokenAddress).balanceOf(claimForwardAddress);
        uint256 eureAmountBefore = IERC20(eureTokenAddress).balanceOf(destinationAddress);
        uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);

		// Set allowance
		vm.startPrank(claimAddress);
		IERC20(gnoTokenAddress).approve(claimForwardAddress, withdrawableAmount);
		uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
			claimAddress,
			claimForwardAddress
		);
		vm.stopPrank();

		assertEq(withdrawableAmount, allowanceAmount);

		emit log_named_uint("withdrawableAmount", withdrawableAmount);
		emit log_named_uint("allowanceAmount", allowanceAmount);

		uint256 gnoAmountBeforeReceived = IERC20(gnoTokenAddress).balanceOf(claimAddress);
		claimForward.claimWithdrawal(claimAddress);
		uint256 gnoAmountReceived = IERC20(gnoTokenAddress).balanceOf(claimAddress) -
			gnoAmountBeforeReceived;
		emit log_named_uint("gnoAmountReceived", gnoAmountReceived);
        claimForward.transferGNO(claimAddress, claimForwardAddress, withdrawableAmount);
		uint256 gnoAmountForwarded = IERC20(gnoTokenAddress).balanceOf(claimForwardAddress);
		emit log_named_uint("gnoAmountForwarded", gnoAmountForwarded);
		assertEq(gnoAmountReceived, withdrawableAmount);

		claimForward.swap(withdrawableAmount);

		uint256 wxdaiAmountAfter = IERC20(wxdaiTokenAddress).balanceOf(claimForwardAddress);
		uint256 wxdaiDifference = wxdaiAmountAfter - wxdaiAmountBefore;
        emit log_named_uint("wxdaiAmountBefore", wxdaiAmountBefore);
        emit log_named_uint("wxdaiAmountAfter", wxdaiAmountAfter);
        emit log_named_uint("wxdaiDifference", wxdaiDifference);
		assert(wxdaiDifference > 0);

        claimForward.curveSwapWxdaiEure(wxdaiDifference);
        uint256 eureAmountAfter= IERC20(eureTokenAddress).balanceOf(destinationAddress);
        uint256 eureDifference = eureAmountAfter - eureAmountBefore;
        emit log_named_uint("eureAmountBefore", eureAmountBefore);
        emit log_named_uint("eureAmountAfter", eureAmountAfter);
        emit log_named_uint("eureDifference", eureDifference);
        assert(eureDifference > 0);

	}
}
