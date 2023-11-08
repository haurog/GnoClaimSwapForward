// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    uint256 gnosisFork;

    Counter public counter;

    function setUp() public {
        gnosisFork = vm.createFork('https://rpc.gnosis.gateway.fm');
        vm.selectFork(gnosisFork);
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_Increment_NonZero() public {
        uint256 number = 532;
        counter.setNumber(number);
        assertEq(counter.number(), number);
        counter.increment();
        assertEq(counter.number(), number+1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function test_withdrawableAmount() public {
        address claimAddress = 0x1c0AcCc24e1549125b5b3c14D999D3a496Afbdb1;
        uint256 withdrawableAmount = counter.getWithdrawableAmount(claimAddress);
        assertEq(withdrawableAmount, 54782517406250000);
    }

}
