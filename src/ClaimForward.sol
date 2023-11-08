// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/Interfaces.sol";
import "forge-std/console.sol";

contract ClaimForward {
    address private GBCDepositContractAddress =
        0x0B98057eA310F4d31F2a452B414647007d1645d9;
    address private GNOTokenAddress =
         0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;

    GBCDepositContract depositContract =
        GBCDepositContract(GBCDepositContractAddress);
    GBCDepositContractVariables depositContractVariables =
        GBCDepositContractVariables(GBCDepositContractAddress);

    function getWithdrawableAmount(
        address claimAddress
    ) public view returns (uint256) {
        return depositContractVariables.withdrawableAmount(claimAddress);
    }

    function claimWithdrawal(address claimAddress) public {
        depositContract.claimWithdrawal(claimAddress);
    }

    // function claimAndForward(address claimAddress) public {
    //     uint256 amount = getWithdrawableAmount(claimAddress);
    //     claimWithdrawal(claimAddress);
    //     IERC20(GNOAddress).transfer(destinationAddress, amount);

    // }
}
