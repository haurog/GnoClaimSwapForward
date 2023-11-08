// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/Interfaces.sol";
import "forge-std/console.sol";

contract ClaimForward {

    address private GBCDepositContractAddress =
        0x0B98057eA310F4d31F2a452B414647007d1645d9;

    function getWithdrawableAmount(
        address claimAddress
    ) public view returns (uint256) {
        GBCDepositContract depositContract = GBCDepositContract(
            GBCDepositContractAddress
        );
        return depositContract.withdrawableAmount(claimAddress);
    }
}
