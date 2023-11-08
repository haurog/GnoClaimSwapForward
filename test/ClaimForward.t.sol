// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ClaimForward} from "../src/ClaimForward.sol";

contract ClaimForwardTest is Test {
    uint256 gnosisFork;

    ClaimForward public claimForward;

    address claimAddress = 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1;

    function setUp() public {
        gnosisFork = vm.createFork('https://rpc.gnosis.gateway.fm');
        vm.selectFork(gnosisFork);
        claimForward = new ClaimForward();
    }

    function test_withdrawableAmount() public {
        uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
        assertEq(withdrawableAmount, 71163386093750000);
    }

    // function test_claimAndForward() public {
    //     uint256 withdrawableAmount = claimForward.getWithdrawableAmount(claimAddress);
    //     claimForward.claimAndForward(claimAddress);
    // }
}
