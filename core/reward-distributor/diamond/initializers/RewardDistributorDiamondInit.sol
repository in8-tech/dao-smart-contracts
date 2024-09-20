// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC721EnumerableTyped} from "../interfaces/IERC721EnumberableTyped.sol";
import {PoolFacet} from "../facets/PoolFacet.sol";
import {IPriceFeed} from "../../../../util/IPriceFeed.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract RewardDistributorDiamondInit {
    AppStorage internal s;

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(
        IERC20 rewardsToken,
        IERC721EnumerableTyped nft,
        IERC20Metadata feeToken,
        address feeAddress,
        uint256 feeAmountUsd,
        IPriceFeed priceFeed,
        uint256 rewardsStartTime,
        uint256 nftWeight,
        address treasury,
        uint256 treasuryWeight,
        bool treasuryEnabled,
        uint256 rewardsRateDivisor,
        address nftActivityAssigner
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.nftActivityAssigner = nftActivityAssigner;

        s.totalPendingRewards = 0;
        s.rewardsToken = rewardsToken;
        s.nft = nft;
        s.feeToken = feeToken;
        s.feeAddress = feeAddress;
        s.feeAmountUsd = feeAmountUsd;
        s.priceFeed = priceFeed;

        s.rewardsStartTime = rewardsStartTime;
        s.treasury = treasury;
        s.userInfo[treasury].areNftsActive = true;
        s.treasuryEnabled = treasuryEnabled;
        if (nftWeight > 0) {
            s.nftWeight = nftWeight;
        } else {
            s.nftWeight = 100;
        }
        if (treasuryWeight > 0) {
            s.treasuryWeight = treasuryWeight;
        } else {
            s.treasuryWeight = 100;
        }

        s.rewardsRateDivisor = rewardsRateDivisor;

        PoolFacet(address(this)).updatePool();
    }
}
