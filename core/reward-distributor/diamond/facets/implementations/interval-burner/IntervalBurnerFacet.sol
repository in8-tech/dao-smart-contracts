// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, Burn} from "../../../libraries/LibAppStorage.sol";
import {IERC20Burnable} from "../../../../../token/extensions/IERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IIntervalBurner} from "../../../interfaces/IIntervalBurner.sol";
import "../../../libraries/LibHelpers.sol";

contract IntervalBurnerFacet is IIntervalBurner {
    AppStorage internal s;

    function intervalBurn() external override {
        if (
            s.rewardsStartTime != 0 &&
            block.timestamp - s.lastIntervalBurnTime >= s.secondsBetweenBurns
        ) {
            uint256 nonRewardedBalance = LibHelpers.releasableToken(
                s.rewardsToken,
                s.totalPendingRewards
            );
            uint256 amountToBurn = 0;
            if (s.burnPercentage > 0) {
                amountToBurn = (nonRewardedBalance * s.burnPercentage) / 100;
            } else {
                if (nonRewardedBalance < s.burnAmount) {
                    amountToBurn = nonRewardedBalance;
                } else {
                    amountToBurn = s.burnAmount;
                }
            }
            // if we have no tokens to burn, just don't burn
            if (amountToBurn == 0) {
                return;
            }
            s.burns.push(Burn(amountToBurn, block.timestamp));
            s.lastIntervalBurnTime = block.timestamp;
            if (address(s.burnDestination) != address(0)) {
                IERC20(address(s.rewardsToken)).transfer(
                    address(s.burnDestination),
                    amountToBurn
                );
            } else {
                IERC20Burnable(address(s.rewardsToken)).burn(amountToBurn);
            }
            emit IntervalBurn(amountToBurn);
        }
    }

    function lastIntervalBurnTime() external view override returns (uint256) {
        return s.lastIntervalBurnTime;
    }
}
