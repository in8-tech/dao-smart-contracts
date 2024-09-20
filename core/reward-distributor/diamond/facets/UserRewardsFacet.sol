// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {AppStorage, UserInfo} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IRewardsPerSecond} from "../interfaces/IRewardsPerSecond.sol";
import {IIntervalBurner} from "../interfaces/IIntervalBurner.sol";
import {PoolFacet} from "../facets/PoolFacet.sol";
import {ACC_REWARDS_PRECISION} from "../libraries/LibConstants.sol";
import {LibPrice} from "../../../libraries/LibPrice.sol";
import {IPriceFeed} from "../../../../util/IPriceFeed.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title RewardDistributor
 * @dev The RewardDistributor contract distributes rewards based on the number of project NFTs held by a user.
 * Rewards per second are updated dynamically based on the amount of rewards left in the contract.
 */
contract UserRewardsFacet {
    AppStorage internal s;

    using SafeERC20 for IERC20;
    /// @dev Event emitted when a user collects their pending rewards from the contract.
    event RewardsCollected(address indexed user, uint256 amount);

    /**
     * @dev View function to see the pending rewards for a given account.
     * @param account The address of the user account to check pending rewards.
     * @return The pending rewards for the given account.
     */
    function pendingRewards(address account) external view returns (uint256) {
        UserInfo storage user = s.userInfo[account];
        uint256 totalWeight = PoolFacet(address(this)).totalRewardsWeight();
        uint256 currAccRewardsPerShare = s.accRewardsPerShare;
        if (block.timestamp > s.lastRewardTime && totalWeight != 0) {
            uint256 secondsSinceLastReward = block.timestamp - s.lastRewardTime;
            uint256 rewards = secondsSinceLastReward * s.totalRewardsPerSecond;

            currAccRewardsPerShare =
                currAccRewardsPerShare +
                (rewards * ACC_REWARDS_PRECISION) /
                totalWeight;
        }

        uint256 weight = rewardsWeight(account);
        uint256 accumulatedRewards = (weight * currAccRewardsPerShare) /
            ACC_REWARDS_PRECISION;
        return accumulatedRewards - user.rewardDebt + user.unpaidRewards;
    }

    /**
     * @dev Collects all pending rewards for the calling user.
     * The rewards are transferred to the user's address.
     */
    function collectRewards(address account) public {
        require(
            collectAvailable(),
            "UserRewardsFacet: Collect is currently not available"
        );
        // EFFECTS
        PoolFacet(address(this)).updatePool();

        UserInfo storage user = s.userInfo[account];
        uint256 weight = rewardsWeight(account);
        uint256 accumulatedRewards = (weight * s.accRewardsPerShare) /
            ACC_REWARDS_PRECISION;
        uint256 pending = accumulatedRewards -
            user.rewardDebt +
            user.unpaidRewards;

        user.rewardDebt = accumulatedRewards;
        user.unpaidRewards = 0;
        s.totalPendingRewards -= pending;

        // INTERACTIONS
        if (pending > 0) {
            s.rewardsToken.safeTransfer(account, pending);
        }
        // charge fee
        if (s.feeAmountUsd > 0) {
            uint256 feeTokenAmount = LibPrice.calculatePrice(
                s.feeAmountUsd,
                s.priceFeed.getPrice(address(s.feeToken)),
                s.priceFeed.decimals(),
                s.feeToken.decimals()
            );
            IERC20(s.feeToken).safeTransferFrom(
                msg.sender,
                s.feeAddress,
                feeTokenAmount
            );
        }

        s.totalRewarded += pending;
        emit RewardsCollected(account, pending);
    }

    /**
     * @dev View function to calculate and retrieve the rewards per second for a given user.
     * The rewards per second are calculated based on the user's rewards weight compared to the total rewards weight in the contract.
     * @param account The address of the user account for which to calculate rewards per second.
     * @return The calculated rewards per second for the given user.
     */
    function rewardsPerSecond(address account) external view returns (uint256) {
        uint256 totalWeight = PoolFacet(address(this)).totalRewardsWeight();

        uint256 weight = rewardsWeight(account);

        if (totalWeight == 0 || weight == 0) {
            return 0;
        }
        return (s.totalRewardsPerSecond * weight) / totalWeight;
    }

    /**
     * @dev View function to get the rewards weight of a given user.
     * Rewards weight is calculated based on the number of staked NFTs for the user.
     * If the user's NFTs are not active, the rewards weight is 0.
     * @param account The address of the user account to check rewards weight.
     * @return The rewards weight for the given user.
     */
    function rewardsWeight(address account) public view returns (uint256) {
        UserInfo storage user = s.userInfo[account];
        if (!user.areNftsActive) {
            return 0;
        }
        return user.stakedNfts * s.nftWeight;
    }

    function setFeeAmountUsd(uint256 amount) public virtual {
        LibDiamond.enforceIsContractOwner();
        s.feeAmountUsd = amount;
    }

    function feeAmountUsd() public view returns (uint256) {
        return s.feeAmountUsd;
    }

    function setFeeAddress(address newFeeAddress) public virtual {
        LibDiamond.enforceIsContractOwner();
        s.feeAddress = newFeeAddress;
    }

    function feeAddress() public view returns (address) {
        return s.feeAddress;
    }

    function setFeeToken(IERC20Metadata newFeeToken) public {
        LibDiamond.enforceIsContractOwner();
        s.feeToken = newFeeToken;
    }

    function feeToken() public view returns (IERC20Metadata) {
        return s.feeToken;
    }

    function setRewardsToken(IERC20 newRewardsToken) public {
        LibDiamond.enforceIsContractOwner();
        s.rewardsToken = newRewardsToken;
    }

    function rewardsToken() public view returns (IERC20) {
        return s.rewardsToken;
    }

    function collectAvailable() public view returns (bool) {
        if (s.rewardsToken == IERC20(address(0))) {
            return false;
        }

        if (s.feeToken == IERC20Metadata(address(0))) {
            return false;
        }

        if (s.feeAddress == address(0)) {
            return false;
        }

        return true;
    }

    function priceFeed() public view returns (address) {
        return address(s.priceFeed);
    }

    function setPriceFeed(address newPriceFeed) public virtual {
        LibDiamond.enforceIsContractOwner();
        s.priceFeed = IPriceFeed(newPriceFeed);
    }
}
