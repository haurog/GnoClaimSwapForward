// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// Minimal definition of some external contracts which I need to call

contract NCTContract {
    uint256 public feeRedeemDivider;
    uint256 public feeRedeemPercentageInBase;
}

/// GBCDepositContract is defined here as a contract to be able to access public variables
contract GBCDepositContract {
    mapping(address => uint256) public withdrawableAmount;
}

/// GBCDepositContract is defined here as an interface to be able to access public mbembers
interface IGBCDepositContract {
    function claimWithdrawal(address _address) external;
}
