// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {AppStorage, UserInfo} from "../libraries/LibAppStorage.sol";
import {PoolFacet} from "./PoolFacet.sol";
import {ACC_REWARDS_PRECISION} from "../libraries/LibConstants.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC721EnumerableTyped} from "../interfaces/IERC721EnumberableTyped.sol";

contract StakingFacet is ERC721Holder {
    AppStorage internal s;

    /// @dev Event emitted when a user stakes one or more NFT tokens into the contract.
    event NftsStaked(address indexed user, uint256[] tokenIds);
    /// @dev Event emitted when a user unstakes one or more NFT tokens from the contract.
    event NftsUnstaked(address indexed user, uint256[] tokenIds);

    /**
     * @dev Stakes NFT tokens for the calling user.
     * The staked NFTs are transferred to the contract.
     * @param _tokenIds The array of NFT token IDs to be staked.
     */
    function stakeTokens(uint256[] calldata _tokenIds) external {
        // CHECKS
        uint256 len = _tokenIds.length;
        require(len != 0, "RewardDistributor: staking zero tokens");

        // EFFECTS
        PoolFacet(address(this)).updatePool();
        _updateUnpaidRewards(msg.sender);

        UserInfo storage user = s.userInfo[msg.sender];

        for (uint256 i = 0; i < len; i++) {
            require(
                s.nft.ownerOf(_tokenIds[i]) == msg.sender,
                "RewardDistributor: token not owned by user"
            );
            s.stakedNfts[msg.sender].push(_tokenIds[i]);
            s.stakedNftsIndex[_tokenIds[i]] = user.stakedNfts;
            user.stakedNfts += 1;
        }

        _updateRewardDebt(msg.sender);
        s.totalStakedNfts += len;
        if (user.areNftsActive) {
            s.totalActiveNfts += len;
            if (s.treasuryEnabled) {
                _updateUnpaidRewards(s.treasury);
                s.userInfo[s.treasury].stakedNfts = s.totalActiveNfts;
                _updateRewardDebt(s.treasury);
            }
        }

        // INTERACTIONS
        for (uint256 i = 0; i < len; i++) {
            s.nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        emit NftsStaked(msg.sender, _tokenIds);
    }

    /**
     * @dev Unstakes NFT tokens for the calling user.
     * The unstaked NFTs are transferred back to the user.
     * @param _tokenIds The array of NFT token IDs to be unstaked.
     */
    function unstakeTokens(uint256[] calldata _tokenIds) external {
        // CHECKS
        uint256 len = _tokenIds.length;
        require(len != 0, "RewardDistributor: unstaking zero tokens");
        UserInfo storage user = s.userInfo[msg.sender];
        require(
            len <= user.stakedNfts,
            "RewardDistributor: unstaking more tokens than are staked"
        );

        // EFFECTS
        PoolFacet(address(this)).updatePool();
        _updateUnpaidRewards(msg.sender);

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 index = s.stakedNftsIndex[tokenId];
            require(
                index < user.stakedNfts &&
                    tokenId == s.stakedNfts[msg.sender][index],
                "RewardDistributor: staked token not owned by user"
            );
            // we store the last token in the index of the token to delete, and
            // then delete the last slot (swap and pop).

            uint256[] storage userStakedNfts = s.stakedNfts[msg.sender];
            uint256 lastTokenId = userStakedNfts[userStakedNfts.length - 1];
            userStakedNfts[index] = lastTokenId;
            s.stakedNftsIndex[lastTokenId] = index;

            delete s.stakedNftsIndex[tokenId];
            userStakedNfts.pop();
            user.stakedNfts -= 1;
        }

        _updateRewardDebt(msg.sender);

        s.totalStakedNfts -= len;
        if (user.areNftsActive) {
            s.totalActiveNfts -= len;
            if (s.treasuryEnabled) {
                _updateUnpaidRewards(s.treasury);
                s.userInfo[s.treasury].stakedNfts = s.totalActiveNfts;
                _updateRewardDebt(s.treasury);
            }
        }

        // INTERACTIONS
        for (uint256 i = 0; i < len; i++) {
            s.nft.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }

        emit NftsUnstaked(msg.sender, _tokenIds);
    }

    function bulkSetAreNftsActive(
        address[] memory _accounts,
        bool[] memory _areNftsActive
    ) public {
        LibDiamond.enforceIsNftActivityAssigner();
        require(
            _accounts.length == _areNftsActive.length,
            "UserRewardsFacet: accounts and areNftsActive must have the same length"
        );
        PoolFacet(address(this)).updatePool();
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(
                _accounts[i] != s.treasury,
                "UserRewardsFacet: treasury cannot be changed"
            );
            UserInfo storage user = s.userInfo[_accounts[i]];
            if (user.areNftsActive == _areNftsActive[i]) {
                continue;
            }

            _updateUnpaidRewards(_accounts[i]);
            user.areNftsActive = _areNftsActive[i];
            _updateRewardDebt(_accounts[i]);
            if (_areNftsActive[i]) {
                s.totalActiveNfts += user.stakedNfts;
            } else {
                s.totalActiveNfts -= user.stakedNfts;
            }
        }
        _updateUnpaidRewards(s.treasury);
        s.userInfo[s.treasury].stakedNfts = s.totalActiveNfts;
        _updateRewardDebt(s.treasury);
    }

    /**
     * @dev View function to get the array of staked NFT token IDs for a given user.
     * @param account The address of the user account to check staked NFTs.
     * @return An array containing the staked NFT token IDs.
     */
    function stakedTokensOfOwner(
        address account
    ) external view returns (uint256[] memory) {
        return s.stakedNfts[account];
    }

    /**
     * @dev View function to get the number of staked NFTs for a given user.
     * @param account The address of the user account to check staked NFTs.
     * @return The number of staked NFTs for the given user.
     */
    function stakedBalanceOf(address account) public view returns (uint256) {
        return s.userInfo[account].stakedNfts;
    }

    function stakedBalanceOfByType(
        address account
    ) public view returns (uint256 founderBalance, uint256 ambassadorBalance) {
        uint256[] memory nfts = s.stakedNfts[account];

        for (uint256 i = 0; i < nfts.length; i++) {
            if (
                s.nft.getNftType(nfts[i]) ==
                IERC721EnumerableTyped.NftType.Founder
            ) {
                founderBalance++;
            } else {
                ambassadorBalance++;
            }
        }
        return (founderBalance, ambassadorBalance);
    }

    /**
     * @dev View function to get the NFT token ID at a given index for a given user.
     * @param account The address of the user account to check staked NFTs.
     * @param index The index position in the staked NFTs array.
     * @return The NFT token ID at the specified index.
     */
    function stakedTokenOfOwnerByIndex(
        address account,
        uint256 index
    ) public view returns (uint256) {
        require(
            index < stakedBalanceOf(account),
            "RewardDistributor: owner index out of bounds"
        );

        return s.stakedNfts[account][index];
    }

    /**
     * @dev View function to get the array of staked NFT token IDs for a given user of a limited size.
     * @param _owner The address of the user account to check staked NFTs.
     * @param _startIndex The starting index for the subset of staked NFTs.
     * @param _pageSize The number of staked NFTs to return.
     * @return An array containing the staked NFT token IDs.
     */
    function stakedTokensOfOwnerSubset(
        address _owner,
        uint256 _startIndex,
        uint256 _pageSize
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = stakedBalanceOf(_owner);
        require(_startIndex < tokenCount, "Start index out of bounds");

        uint256 endIndex = (_startIndex + _pageSize) > tokenCount
            ? tokenCount
            : (_startIndex + _pageSize);
        uint256[] memory tokenIds = new uint256[](endIndex - _startIndex);
        for (uint256 i = _startIndex; i < endIndex; i++) {
            tokenIds[i - _startIndex] = stakedTokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /**
     * @dev Internal function to update the unpaid rewards for a given user.
     * @param account The address of the user account to update unpaid rewards.
     */
    function _updateUnpaidRewards(address account) private {
        UserInfo storage user = s.userInfo[account];
        uint256 weight = user.areNftsActive ? user.stakedNfts * s.nftWeight : 0;

        if (weight > 0) {
            user.unpaidRewards +=
                ((weight * s.accRewardsPerShare) / ACC_REWARDS_PRECISION) -
                user.rewardDebt;
        }
    }

    /**
     * @dev Internal function to update the reward debt for a given user.
     * @param account The address of the user account to update reward debt.
     */
    function _updateRewardDebt(address account) private {
        UserInfo storage user = s.userInfo[account];
        uint256 weight = user.areNftsActive ? user.stakedNfts * s.nftWeight : 0;

        user.rewardDebt =
            (weight * s.accRewardsPerShare) /
            ACC_REWARDS_PRECISION;
    }

    function areNftsActive(address account) public view returns (bool) {
        return s.userInfo[account].areNftsActive;
    }

    function totalStakedNfts() external view returns (uint256) {
        return s.totalStakedNfts;
    }

    function totalActiveNfts() external view returns (uint256) {
        return s.totalActiveNfts;
    }

    function totalTreasuryNfts() external view returns (uint256) {
        return s.userInfo[s.treasury].stakedNfts;
    }
}
