// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

contract ClaimForward {
    using SafeERC20 for IERC20;

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
        }

    BatchSwapStep[] batchSwapSteps;

    address private GBCDepositContractAddress =
        0x0B98057eA310F4d31F2a452B414647007d1645d9;
    address private GNOTokenAddress =
        0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
    address private destinationAddress =
        0xAeC36E243159FC601140Db90da6961133630f15D;  // Gnosis pay wallet

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

    function claimAndForward(address claimAddress) public {
        uint256 withdrawableAmount = getWithdrawableAmount(claimAddress);
        claimWithdrawal(claimAddress);
        IERC20(GNOTokenAddress).transferFrom(claimAddress, destinationAddress, withdrawableAmount);
    }


    function swap(uint256 withdrawableAmount) public {



        BatchSwapStep memory step1 = BatchSwapStep({
                poolId: 0x4683e340a8049261057d5ab1b29c8d840e75695e00020000000000000000005a,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: withdrawableAmount,
                userData: ""
                });
        BatchSwapStep memory step2 = BatchSwapStep({
                poolId: 0xbc2acf5e821c5c9f8667a36bb1131dad26ed64f9000200000000000000000063,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: ""
                });
        BatchSwapStep memory step3 = BatchSwapStep({
                poolId: 0xdd439304a77f54b1f7854751ac1169b279591ef7000000000000000000000064,
                assetInIndex: 2,
                assetOutIndex: 3,
                amount: 0,
                userData: ""
                });
        batchSwapSteps.push(step1);
        batchSwapSteps.push(step2);
        batchSwapSteps.push(step3);



    }


}
