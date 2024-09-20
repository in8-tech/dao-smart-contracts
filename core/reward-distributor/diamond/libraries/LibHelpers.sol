// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibHelpers {
    function releasableToken(IERC20 rewardsToken, uint256 totalPendingRewards) internal view returns (uint256) {
        uint256 totalTokens = rewardsToken.balanceOf(address(this));
        if (totalTokens == 0) {
          return 0;
        }
        if (totalPendingRewards > totalTokens) {
          return 0;
        }
        uint256 releasable = totalTokens - totalPendingRewards;
        return releasable;
    }
}