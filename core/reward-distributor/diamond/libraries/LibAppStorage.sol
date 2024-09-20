//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721EnumerableTyped} from "../interfaces/IERC721EnumberableTyped.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPriceFeed} from "../../../../util/IPriceFeed.sol";

/**
 * @dev Struct representing user-specific staking information.
 * @param stakedNfts Amount of NFTs staked by the user.
 * @param rewardDebt User's reward debt to keep track of pending rewards.
 * @param unpaidRewards Accumulated but unpaid rewards for the user.
 */
struct UserInfo {
    uint256 stakedNfts;
    uint256 rewardDebt;
    uint256 unpaidRewards;
    bool areNftsActive;
}

using SafeERC20 for IERC20;

struct Burn {
    uint256 amount;
    uint256 timestamp;
}

// AppStorage.sol
struct AppStorage {
    uint256 accRewardsPrecision;
    /// @dev Weight of a single NFT in the reward calculation.
    uint256 nftWeight;
    /// @dev Time when the last reward was claimed.
    uint256 lastRewardTime;
    /// @dev Time when the NFTs pass their viability threshold.
    uint256 viabilityTime;
    /// @dev Accumulated rewards per share, scaled by ACC_REWARDS_PRECISION.
    uint256 accRewardsPerShare;
    /// @dev Total rewards per second to be distributed among stakers.
    uint256 totalRewardsPerSecond;
    /// @dev The divisor to use when calculating the rewards rate per second.
    uint256 rewardsRateDivisor;
    /// @dev Total pending rewards in the contract.
    uint256 totalPendingRewards;
    /// @dev A date to limit when the rewards start.
    uint256 rewardsStartTime;
    /// @dev Total number of staked NFTs in the contract.
    uint256 totalStakedNfts;
    /// @dev Total number of active NFTs in the contract.
    uint256 totalActiveNfts;
    /// @dev Mapping to store user-specific staking information.
    mapping(address => UserInfo) userInfo;
    /// @dev Mapping to track the index of NFT token IDs in the stakedNfts array.
    /// @dev Similar implementation to ERC721Enumerable.
    mapping(uint256 => uint256) stakedNftsIndex;
    /// @dev Mapping to store the array of staked NFT token IDs for a given user.
    mapping(address => uint256[]) stakedNfts;
    /// @dev ERC721 token contract representing the NFTs eligible for staking.
    IERC721EnumerableTyped nft;
    /// @dev ERC20 token contract representing the rewards tokens.
    IERC20 rewardsToken;
    /// @dev ERC20 token contract representing the fee tokens.
    IERC20Metadata feeToken;
    /// @dev Wallet to accept fee for collecting rewards.
    address feeAddress;
    /// @dev Fee amount to collect rewards.
    uint256 feeAmountUsd;
    /// @dev An array of all of the burns that have taken place.
    Burn[] burns;
    /// @dev The initial supply for calculating distributions when part of a half life.
    uint256 initialSupply;
    /// @dev The number of years to offset distributions when part of a half life.
    uint256 yearsSinceRewardsStartTime;
    /// @dev The interval for the interval burns.
    uint256 secondsBetweenBurns;
    /// @dev The percentage of the pool to burn on the interval.
    uint8 burnPercentage;
    /// @dev The amount to burn if it's an exact amount instead of a percentage.
    uint256 burnAmount;
    /// @dev If the contract only supports burning by the owner, send the token to the owner address and burn it from there manually.
    address burnDestination;
    /// @dev Last time a burn successfully took place. This is initially the start time.
    uint256 lastIntervalBurnTime;
    /// @dev Address for treasury wallet.
    address treasury;
    uint256 treasuryWeight;
    /// @dev Treasury enabled
    bool treasuryEnabled;
    /// @dev Price feed contract.
    IPriceFeed priceFeed;
    /// @dev Total amount of rewards that have been rewarded.
    uint256 totalRewarded;
}
