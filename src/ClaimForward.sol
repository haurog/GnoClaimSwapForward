// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/Interfaces.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IAsset.sol";


import "forge-std/console.sol";

contract ClaimForward {
    // using SafeERC20 for IERC20;

    IVault.BatchSwapStep[] batchSwapSteps;

    address[] assets = [
	0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb, // GNO
	0x6C76971f98945AE98dD7d4DFcA8711ebea946eA6, // wstETH
	0xaf204776c7245bF4147c2612BF6e5972Ee483701, // sDAI
	0xcB444e90D8198415266c6a2724b7900fb12FC56E  // EURe
    ];

    address private GBCDepositContractAddress =
        0x0B98057eA310F4d31F2a452B414647007d1645d9;
    address private GNOTokenAddress = assets[0];
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



        IVault.BatchSwapStep memory step1 = IVault.BatchSwapStep({
                poolId: 0x4683e340a8049261057d5ab1b29c8d840e75695e00020000000000000000005a,
                assetInIndex: 0,
                assetOutIndex: 1,
                amount: withdrawableAmount,
                userData: ""
                });
        IVault.BatchSwapStep memory step2 = IVault.BatchSwapStep({
                poolId: 0xbc2acf5e821c5c9f8667a36bb1131dad26ed64f9000200000000000000000063,
                assetInIndex: 1,
                assetOutIndex: 2,
                amount: 0,
                userData: ""
                });
        IVault.BatchSwapStep memory step3 = IVault.BatchSwapStep({
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
