// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
// import "balancer-v2-monorepo/pkg/interfaces/contracts/vault/IAsset.sol";

import "forge-std/console.sol";

/// @title Gnosis validator claim swap forward
/// @author haurog
/// @notice This contract claims my validator rewards, swaps them to EURe and forwards
/// them to my gnosis pay wallet. The contract needs to have GNO allowance from the
/// claim address, otherwise it cannot swap and forward the funds.

contract ClaimSwapForward is Ownable {
	// using SafeERC20 for IERC20;

	address private gbcDepositContractAddress = 0x0B98057eA310F4d31F2a452B414647007d1645d9;
	address private gnoTokenAddress = 0x9C58BAcC331c9aa871AFD802DB6379a98e80CEdb;
	address private wxdaiTokenAddress = 0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d;
	address private eureTokenAddress = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
	address private destinationAddress = 0xAeC36E243159FC601140Db90da6961133630f15D; // Gnosis pay wallet

	GBCDepositContract depositContract = GBCDepositContract(gbcDepositContractAddress);
	GBCDepositContractVariables depositContractVariables =
		GBCDepositContractVariables(gbcDepositContractAddress);

	constructor() Ownable(msg.sender) {}

	/// @notice This is the main functionality. Which does everything (claim, swap and forward).
	/// @param claimAddress address for which to claim .
	function claimSwapAndForward(address claimAddress) public {
		uint256 withdrawableAmount = getWithdrawableAmount(claimAddress);
		claimWithdrawal(claimAddress);
		IERC20(gnoTokenAddress).transferFrom(claimAddress, address(this), withdrawableAmount);
		balancerSwapGnoToWxdai(withdrawableAmount);

		uint256 wxdaiAmount = IERC20(wxdaiTokenAddress).balanceOf(address(this));
		curveSwapWxdaiEure(wxdaiAmount);
		transferAllEureToDestination();
	}

	/// @notice Helper function to know how much GNO can be claimed for the claimAddress.
	/// @param claimAddress address for which to claim.
	function getWithdrawableAmount(address claimAddress) public view returns (uint256) {
		return depositContractVariables.withdrawableAmount(claimAddress);
	}

	/// @notice Claim the rewards.
	/// @param claimAddress address for which to claim.
	function claimWithdrawal(address claimAddress) public {
		depositContract.claimWithdrawal(claimAddress);
	}

	/// @notice Claim and forward the rewards as GNO, without swapping.
	/// @param claimAddress address for which to claim.
	function claimAndForward(address claimAddress) public {
		uint256 withdrawableAmount = getWithdrawableAmount(claimAddress);
		claimWithdrawal(claimAddress);
		IERC20(gnoTokenAddress).transferFrom(claimAddress, destinationAddress, withdrawableAmount);
	}

	/// @notice First swap step from GNO to wxDAI using balancer. Only public to run tests.
	/// @param gnoAmount amount of GNO to swap.
	function balancerSwapGnoToWxdai(uint256 gnoAmount) public {
		address vaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
		Balancer vaultContract = Balancer(vaultAddress);
		bytes32 poolId = 0xa99fd9950b5d5dceeaf4939e221dca8ca9b938ab000100000000000000000025;

		// Poor mans in-block sandwich prevention. If the pool has been touched in the same block, revert.
		// There is about 1 balancer transaction per 100 blocks, so it has a 1% chance to give a false positive.
		(, , uint256 lastChangeBlock, ) = vaultContract.getPoolTokenInfo(
			poolId,
			IERC20(gnoTokenAddress)
		);
		// console.logUint(lastChangeBlock);
		// console.logUint(block.number);
		require(
			lastChangeBlock < block.number,
			"Balancer pool has been used in this block already. Revert to prevent in-block sandwiching attacks."
		);

		Balancer.SwapKind kind = Balancer.SwapKind.GIVEN_IN;

		Balancer.SingleSwap memory singleSwapStruct = Balancer.SingleSwap({
			poolId: poolId,
			kind: kind,
			assetIn: IAsset(address(gnoTokenAddress)),
			assetOut: IAsset(address(wxdaiTokenAddress)),
			amount: gnoAmount,
			userData: ""
		});

		Balancer.FundManagement memory fundsManagementStruct = Balancer.FundManagement({
			sender: address(this),
			fromInternalBalance: false,
			recipient: payable(address(this)),
			toInternalBalance: false
		});

		// Set allowance for balancer contract
		IERC20(gnoTokenAddress).approve(vaultAddress, gnoAmount);

		uint256 minReceive = 0;
		vaultContract.swap(singleSwapStruct, fundsManagementStruct, minReceive, block.timestamp);
	}

	/// @notice Second swap step from wxDAI to EURe using curve. Only public to run tests.
	/// @param wxdaiAmount amount of wxDAI to swap.
	function curveSwapWxdaiEure(uint256 wxdaiAmount) public {
		address curveAddress = 0xE3FFF29d4DC930EBb787FeCd49Ee5963DADf60b6;
		uint256 maxDifferenceAccepted = 990; // = 0.990 =1 % difference between oracle price and received
		Curve curveContract = Curve(curveAddress);
		uint256 oraclePrice = curveContract.price_oracle(); // wxDAI you get for 1 EURe multiplied by 1e18

		uint256 minReceive = 0; // TODO: Can be sandwiched to oblivion.
		IERC20(wxdaiTokenAddress).approve(curveAddress, wxdaiAmount);
		// Pool tokens 0=EURe, 1=wxDAI, 2=USDC,3=USDT
		uint inTokenIndex = 1; // wxDAI
		uint outTokenIndex = 0; // EURe
		curveContract.exchange_underlying(inTokenIndex, outTokenIndex, wxdaiAmount, minReceive);
		uint256 eureReceived = IERC20(eureTokenAddress).balanceOf(address(this));
		uint256 minimallyAcceptedEure = (wxdaiAmount / (oraclePrice / 1e15)) *
			maxDifferenceAccepted;

		// console.logUint(oraclePrice);
		// console.logUint(wxdaiAmount / (oraclePrice/1e15) * 1000);
		// console.logUint(eureReceived);
		// console.logUint(minimallyAcceptedEure);

		require(
			eureReceived > minimallyAcceptedEure,
			"EURe amount received lower than expected from the oracle price. Revert to prevent sandwiching attacks."
		);
	}

	/// @notice Transfer all the EURe in this contract to the destination address.
	function transferAllEureToDestination() private {
		uint256 amount = IERC20(eureTokenAddress).balanceOf(address(this));
		IERC20(eureTokenAddress).transfer(destinationAddress, amount);
	}
}
