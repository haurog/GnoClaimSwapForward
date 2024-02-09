// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import { Test, console2 } from "forge-std/Test.sol";
import { ClaimSwapForward } from "../src/ClaimSwapForward.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimSwapForwardTest is Test {
	uint256 gnosisFork;
	ClaimSwapForward public claimSwapForward;

	address claimAddress = 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1;
	address gnoTokenAddress = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
	address wxdaiTokenAddress = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
	address eureTokenAddress = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
	address destinationAddress = 0xAeC36E243159FC601140Db90da6961133630f15D; // Gnosis pay wallet

	function setUp() public {
		// gnosisFork = vm.createFork("https://rpc.gnosis.gateway.fm");
		gnosisFork = vm.createFork("http://192.168.1.125:8545");
		vm.selectFork(gnosisFork);
		claimSwapForward = new ClaimSwapForward();
	}

	function test_getWithdrawableAmount() public {
		uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
		emit log_named_uint("withdrawableAmount: ", withdrawableAmount);
	}

	function test_ownership() public {
		emit log_named_address("owner: ", claimSwapForward.owner());
		assertEq(claimSwapForward.owner(), 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
		claimSwapForward.transferOwnership(claimAddress);
		assertEq(claimSwapForward.owner(), claimAddress);
	}

	function test_sandwichPreventionParameters() public {
		// Balancer part
		assertEq(claimSwapForward.balancerSandwichPrevention(), true);
		claimSwapForward.changeBalancerSandwichPrevention(false);
		assertEq(claimSwapForward.balancerSandwichPrevention(), false);
		vm.startPrank(claimAddress);
		vm.expectRevert();
		claimSwapForward.changeBalancerSandwichPrevention(false);
		vm.stopPrank();

		// Curve Part
		assertEq(claimSwapForward.curveMaxDiff(), 990);
		claimSwapForward.changeCurveMaxDiffSandwichPrevention(995);
		assertEq(claimSwapForward.curveMaxDiff(), 995);
		vm.startPrank(claimAddress);
		vm.expectRevert();
		claimSwapForward.changeCurveMaxDiffSandwichPrevention(990);
		vm.stopPrank();
	}

	function test_claimSwapAndForward() public {
		address claimSwapForwardAddress = address(claimSwapForward);
		uint256 eureAmountBefore = IERC20(eureTokenAddress).balanceOf(destinationAddress);

		// Set allowance
		vm.startPrank(claimAddress);
		uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
		IERC20(gnoTokenAddress).approve(claimSwapForwardAddress, withdrawableAmount);
		uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
			claimAddress,
			claimSwapForwardAddress
		);
		claimSwapForward.setForwardingAddress(destinationAddress);
		vm.stopPrank();

		assertEq(withdrawableAmount, allowanceAmount);

		claimSwapForward.claimSwapAndForward(claimAddress);
		uint256 eureAmountAfter = IERC20(eureTokenAddress).balanceOf(destinationAddress);
		uint256 eureDifference = eureAmountAfter - eureAmountBefore;
		emit log_named_uint("eureAmountBefore", eureAmountBefore);
		emit log_named_uint("eureAmountAfter", eureAmountAfter);
		emit log_named_uint("eureDifference", eureDifference);
		assert(eureDifference > 0);
	}

	function test_claimSwapAndForwardRevertAllowance() public {
		address claimSwapForwardAddress = address(claimSwapForward);

		// Set allowance
		vm.startPrank(claimAddress);
		uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
		IERC20(gnoTokenAddress).approve(claimSwapForwardAddress, withdrawableAmount - 100);
		uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
			claimAddress,
			claimSwapForwardAddress
		);
		claimSwapForward.setForwardingAddress(destinationAddress);
		vm.stopPrank();

		assert(allowanceAmount < withdrawableAmount);

		vm.expectRevert("Approval amount too low, cannot transfer GNO to contract to do the swap.");
		claimSwapForward.claimSwapAndForward(claimAddress);
	}

	function test_claimSwapAndForwardRevertForwardingAddress() public {
		address claimSwapForwardAddress = address(claimSwapForward);

		// Set allowance
		vm.startPrank(claimAddress);
		uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
		IERC20(gnoTokenAddress).approve(claimSwapForwardAddress, withdrawableAmount);
		vm.stopPrank();

		vm.expectRevert("No forwarding Address set for the claimAddress. Cannot forward the swapped funds.");
		claimSwapForward.claimSwapAndForward(claimAddress);
	}

	// function test_claimWithdrawal() public {
	// 	uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
	// 	uint256 amountBefore = IERC20(gnoTokenAddress).balanceOf(claimAddress);
	// 	claimSwapForward.claimWithdrawal(claimAddress);
	// 	uint256 amountAfter = IERC20(gnoTokenAddress).balanceOf(claimAddress);
	// 	assertEq(amountAfter - amountBefore, withdrawableAmount);
	// }

	// function test_claimAndForward() public {
	// 	address claimSwapForwardAddress = address(claimSwapForward);

	// 	uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);
	// 	emit log_named_uint("withdrawableAmount", withdrawableAmount);
	// 	uint256 amountBefore = IERC20(gnoTokenAddress).balanceOf(destinationAddress);

	// 	// Set allowance
	// 	vm.startPrank(claimAddress);
	// 	IERC20(gnoTokenAddress).approve(claimSwapForwardAddress, withdrawableAmount);
	// 	uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
	// 		claimAddress,
	// 		claimSwapForwardAddress
	// 	);
	// 	vm.stopPrank();

	// 	assertEq(withdrawableAmount, allowanceAmount);

	// 	claimSwapForward.claimAndForward(claimAddress);

	// 	uint256 amountAfter = IERC20(gnoTokenAddress).balanceOf(destinationAddress);
	// 	uint difference = amountAfter - amountBefore;
	// 	assertEq(difference, withdrawableAmount);
	// }

	// function test_claimandSwap() public {
	// 	address claimSwapForwardAddress = address(claimSwapForward);
	// 	uint256 wxdaiAmountBefore = IERC20(wxdaiTokenAddress).balanceOf(claimSwapForwardAddress);
	// 	uint256 eureAmountBefore = IERC20(eureTokenAddress).balanceOf(claimSwapForwardAddress);
	// 	uint256 withdrawableAmount = claimSwapForward.getWithdrawableAmount(claimAddress);

	// 	// Set allowance
	// 	vm.startPrank(claimAddress);
	// 	IERC20(gnoTokenAddress).approve(claimSwapForwardAddress, withdrawableAmount);
	// 	uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(
	// 		claimAddress,
	// 		claimSwapForwardAddress
	// 	);
	// 	vm.stopPrank();

	// 	assertEq(withdrawableAmount, allowanceAmount);

	// 	emit log_named_uint("withdrawableAmount", withdrawableAmount);
	// 	emit log_named_uint("allowanceAmount", allowanceAmount);

	// 	uint256 gnoAmountBeforeReceived = IERC20(gnoTokenAddress).balanceOf(claimAddress);
	// 	claimSwapForward.claimWithdrawal(claimAddress);
	// 	uint256 gnoAmountReceived = IERC20(gnoTokenAddress).balanceOf(claimAddress) -
	// 		gnoAmountBeforeReceived;
	// 	emit log_named_uint("gnoAmountReceived", gnoAmountReceived);
	// 	vm.startPrank(claimSwapForwardAddress);
	// 	IERC20(gnoTokenAddress).transferFrom(
	// 		claimAddress,
	// 		claimSwapForwardAddress,
	// 		withdrawableAmount
	// 	);
	// 	vm.stopPrank();
	// 	uint256 gnoAmountForwarded = IERC20(gnoTokenAddress).balanceOf(claimSwapForwardAddress);
	// 	emit log_named_uint("gnoAmountForwarded", gnoAmountForwarded);
	// 	assertEq(gnoAmountReceived, withdrawableAmount);

	// 	claimSwapForward.balancerSwapGnoToWxdai(withdrawableAmount);

	// 	uint256 wxdaiAmountAfter = IERC20(wxdaiTokenAddress).balanceOf(claimSwapForwardAddress);
	// 	uint256 wxdaiDifference = wxdaiAmountAfter - wxdaiAmountBefore;
	// 	emit log_named_uint("wxdaiAmountBefore", wxdaiAmountBefore);
	// 	emit log_named_uint("wxdaiAmountAfter", wxdaiAmountAfter);
	// 	emit log_named_uint("wxdaiDifference", wxdaiDifference);
	// 	assert(wxdaiDifference > 0);

	// 	claimSwapForward.curveSwapWxdaiEure(wxdaiDifference);
	// 	uint256 eureAmountAfter = IERC20(eureTokenAddress).balanceOf(claimSwapForwardAddress);
	// 	uint256 eureDifference = eureAmountAfter - eureAmountBefore;
	// 	emit log_named_uint("eureAmountBefore", eureAmountBefore);
	// 	emit log_named_uint("eureAmountAfter", eureAmountAfter);
	// 	emit log_named_uint("eureDifference", eureDifference);
	// 	assert(eureDifference > 0);
	// }
}
