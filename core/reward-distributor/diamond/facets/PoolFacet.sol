// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IRewardsPerSecond} from "../interfaces/IRewardsPerSecond.sol";
import {IIntervalBurner} from "../interfaces/IIntervalBurner.sol";
import {ACC_REWARDS_PRECISION} from "../libraries/LibConstants.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ACC_REWARDS_PRECISION} from "../libraries/LibConstants.sol";
import "../libraries/LibHelpers.sol";

contract PoolFacet {
    AppStorage internal s;

    using SafeERC20 for IERC20;
    /// @dev Event emitted when the contract's reward distribution parameters are updated.
    event LogUpdatePool(
        uint256 lastRewardTime,
        uint256 totalRewardsPerSecond,
        uint256 accRewardsPerShare,
        uint256 totalRewardsWeight,
        uint256 totalStakedNfts
    );

    /**
     * @dev Updates the reward variables to be up-to-date.
     * It calculates and accumulates the rewards per share based on the time passed since the last update.
     * Also updates the rewards per second and total pending rewards.
     */
    function updatePool() public {
        if (block.timestamp > s.lastRewardTime) {
            uint256 weight = totalRewardsWeight();

            if (weight > 0) {
                uint256 secondsSinceLastReward = block.timestamp -
                    s.lastRewardTime;
                uint256 rewards = secondsSinceLastReward *
                    s.totalRewardsPerSecond;
                uint256 releasable = LibHelpers.releasableToken(
                    s.rewardsToken,
                    s.totalPendingRewards
                );
                if (releasable < rewards) {
                    // If this scenario ever happens, there are less tokens than promised rewards and the remaining token should be the end of it
                    rewards = releasable;
                    // If this scenario ever happens, the amount of token is gone and distributions should be terminated
                    s.totalRewardsPerSecond = 0;
                }

                s.accRewardsPerShare =
                    s.accRewardsPerShare +
                    (rewards * ACC_REWARDS_PRECISION) /
                    weight;
                s.totalPendingRewards += rewards;
            }

            s.lastRewardTime = block.timestamp;
            if (
                IERC165(address(this)).supportsInterface(
                    type(IIntervalBurner).interfaceId
                )
            ) {
                IIntervalBurner(address(this)).intervalBurn();
            }
            IRewardsPerSecond(address(this)).updateTotalRewardsPerSecond();
            emit LogUpdatePool(
                s.lastRewardTime,
                s.totalRewardsPerSecond,
                s.accRewardsPerShare,
                weight,
                s.totalStakedNfts
            );
        }
    }

    /**
     * @dev View function to get the total rewards weight in the contract.
     * Total rewards weight is calculated based on the total number of staked NFTs.
     * @return The total rewards weight in the contract.
     */
    function totalRewardsWeight() public view returns (uint256) {
        return (s.totalActiveNfts * s.nftWeight) + totalTreasuryWeight();
    }

    function totalTreasuryWeight() public view returns (uint256) {
        return (s.userInfo[s.treasury].stakedNfts * s.treasuryWeight);
    }

    /**
     * @dev View function to calculate and retrieve the rewards per second for a single nft.
     * @return The calculated rewards per second for the given user.
     */
    function nftRewardsPerSecond() external view returns (uint256) {
        uint256 totalWeight = totalRewardsWeight();
        if (totalWeight == 0) {
            return 0;
        }
        return (s.totalRewardsPerSecond * s.nftWeight) / totalWeight;
    }

    function setRewardsStartTime(uint256 _rewardsStartTime) public virtual {
        LibDiamond.enforceIsContractOwner();
        require(
            s.rewardsStartTime == 0,
            "PoolFacet: rewardsStartTime already set"
        );
        if (
            IERC165(address(this)).supportsInterface(
                type(IIntervalBurner).interfaceId
            )
        ) {
            s.lastIntervalBurnTime = _rewardsStartTime;
        }
        s.rewardsStartTime = _rewardsStartTime;
    }

    function rewardsStartTime() external view returns (uint256) {
        return s.rewardsStartTime;
    }

    function totalRewardsPerSecond() external view returns (uint256) {
        return s.totalRewardsPerSecond;
    }

    function totalPendingRewards() external view returns (uint256) {
        return s.totalPendingRewards;
    }

    function totalRewarded() external view returns (uint256) {
        return s.totalRewarded;
    }

    function releaseUnrewardedTokens(address account) external {
        LibDiamond.enforceIsContractOwner();
        updatePool();
        uint256 totalTokens = s.rewardsToken.balanceOf(address(this));
        uint256 releasable = totalTokens - s.totalPendingRewards;
        s.rewardsToken.safeTransfer(account, releasable);
        s.totalRewardsPerSecond = 0;
        updatePool();
    }

    function releasableUnrewardedTokens() public view returns (uint256) {
        return
            LibHelpers.releasableToken(s.rewardsToken, s.totalPendingRewards);
    }

    function setTreasury(address newTreasury) public {
        LibDiamond.enforceIsContractOwner();
        s.userInfo[newTreasury] = s.userInfo[s.treasury];
        delete s.userInfo[s.treasury];
        s.treasury = newTreasury;
    }

    function treasury() external view returns (address) {
        return s.treasury;
    }
}
