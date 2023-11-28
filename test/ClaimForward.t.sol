// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ClaimForward} from "../src/ClaimForward.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimForwardTest is Test {
    uint256 gnosisFork;
    ClaimForward public claimForward;

    address claimAddress = 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1;
    address gnoTokenAddress = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address destinationAddress = 0xAeC36E243159FC601140Db90da6961133630f15D;  // Gnosis pay wallet

    function setUp() public {
        gnosisFork = vm.createFork('https://rpc.gnosis.gateway.fm');
        vm.selectFork(gnosisFork);
        claimForward = new ClaimForward();
    }

    // function test_withdrawableAmount() public {
    //     uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
    //     assertEq(withdrawableAmount, 58958968156250000);
    // }

    function test_claimAndForward() public {
        address bob = address(claimAddress);
        address claimForwardAddress = address(claimForward);

        uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
        uint256 amountBefore = IERC20(gnoTokenAddress).balanceOf(destinationAddress);

        // Set allowance
        vm.startPrank(bob);
        IERC20(gnoTokenAddress).approve(claimForwardAddress, withdrawableAmount);
        uint256 allowanceAmount = IERC20(gnoTokenAddress).allowance(claimAddress, claimForwardAddress);
        vm.stopPrank();

        assertEq(withdrawableAmount, allowanceAmount);

        claimForward.claimAndForward(claimAddress);

        uint256 amountAfter = IERC20(gnoTokenAddress).balanceOf(destinationAddress);
        uint difference = amountAfter - amountBefore;
        assertEq(difference, withdrawableAmount);

    }
}
