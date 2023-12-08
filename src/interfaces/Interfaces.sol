// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// Minimal definition of some external contracts which I need to call

contract NCTContract {
    uint256 public feeRedeemDivider;
    uint256 public feeRedeemPercentageInBase;
}

/// GBCDepositContractVariables is defined here as a contract to be able to access public variables
contract GBCDepositContractVariables {
    mapping(address => uint256) public withdrawableAmount;
}

/// GBCDepositContract is defined here as an interface to be able to access public functions
interface GBCDepositContract {
    function claimWithdrawal(address _address) external;
}


interface Curve {
    // some interfaces claim the i and j input to be int128, but they are uint256
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function price_oracle() external returns(uint256);
}
