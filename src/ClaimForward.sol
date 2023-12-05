// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/Interfaces.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IAsset.sol";

import "forge-std/console.sol";

contract ClaimForward {
	// using SafeERC20 for IERC20;

	address private gbcDepositContractAddress = 0x0B98057eA310F4d31F2a452B414647007d1645d9;
	address private gnoTokenAddress = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
	address private wxdaiTokenAddress = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
	address private eureTokenAddress = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
	address private destinationAddress = 0xAeC36E243159FC601140Db90da6961133630f15D; // Gnosis pay wallet

	GBCDepositContract depositContract = GBCDepositContract(gbcDepositContractAddress);
	GBCDepositContractVariables depositContractVariables =
		GBCDepositContractVariables(gbcDepositContractAddress);

	function getWithdrawableAmount(address claimAddress) public view returns (uint256) {
		return depositContractVariables.withdrawableAmount(claimAddress);
	}

	function claimWithdrawal(address claimAddress) public {
		depositContract.claimWithdrawal(claimAddress);
	}

	function transferGNO(address from, address to, uint256 amount) public {
		IERC20(gnoTokenAddress).transferFrom(from, to, amount);
	}

	function claimAndForward(address claimAddress) public {
		uint256 withdrawableAmount = getWithdrawableAmount(claimAddress);
		claimWithdrawal(claimAddress);
		transferGNO(claimAddress, destinationAddress, withdrawableAmount);
	}

	function swap(uint256 withdrawableAmount) public {
		address vaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

		IVault vaultContract = IVault(vaultAddress);

		IVault.SwapKind kind = IVault.SwapKind.GIVEN_IN;

		IVault.SingleSwap memory singleSwapStruct = IVault.SingleSwap({
			poolId: 0xa99fd9950b5d5dceeaf4939e221dca8ca9b938ab000100000000000000000025,
			kind: kind,
			assetIn: IAsset(address(gnoTokenAddress)),
			assetOut: IAsset(address(wxdaiTokenAddress)),
			amount: withdrawableAmount,
			userData: ""
		});

		IVault.FundManagement memory fundsManagementStruct = IVault.FundManagement({
			sender: address(this),
			fromInternalBalance: false,
			recipient: payable(address(this)),
			toInternalBalance: false
		});

		// Set allowance for balancer contract
		IERC20(gnoTokenAddress).approve(vaultAddress, withdrawableAmount);

		uint256 minReceive = 0; // TODO: Can be sandwiched to oblivion.
		vaultContract.swap(singleSwapStruct, fundsManagementStruct, minReceive, block.timestamp);
	}
}
