// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage} from "../../../libraries/LibAppStorage.sol";
import {LibDiamond} from "../../../libraries/LibDiamond.sol";
import {PoolFacet} from "../../PoolFacet.sol";
import {SECONDS_IN_DAY} from "../../../libraries/LibConstants.sol";
import {IRewardsPerSecond} from "../../../interfaces/IRewardsPerSecond.sol";

contract PerpetualRewardsPerSecondFacet is IRewardsPerSecond {
    AppStorage internal s;

    function updateTotalRewardsPerSecond() external {
        uint256 rewardsPool = s.rewardsToken.balanceOf(address(this)) -
            s.totalPendingRewards;
        s.totalRewardsPerSecond =
            rewardsPool /
            s.rewardsRateDivisor /
            SECONDS_IN_DAY;
    }

    function setRewardsRateDivisor(
        uint256 _perpetualRateDivisor
    ) public virtual {
        LibDiamond.enforceIsContractOwner();
        s.rewardsRateDivisor = _perpetualRateDivisor;
    }
}
