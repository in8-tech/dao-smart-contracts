// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IIntervalBurner} from "../interfaces/IIntervalBurner.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract IntervalBurnerInit {
    AppStorage internal s;

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(
        uint256 secondsBetweenBurns,
        uint256 burnPercentageOrAmount,
        address burnDestination,
        bool isPercentage
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IIntervalBurner).interfaceId] = true;
        s.secondsBetweenBurns = secondsBetweenBurns;
        s.burnDestination = burnDestination;

        if (isPercentage) {
            require(
                burnPercentageOrAmount <= 100,
                "IntervalBurnerInit: burn percentage must be less than or equal to 100"
            );
            s.burnPercentage = uint8(burnPercentageOrAmount);
        } else {
            require(
                burnPercentageOrAmount > 0,
                "IntervalBurnerInit: burn amount must be greater than 0"
            );
            s.burnAmount = burnPercentageOrAmount;
        }

        if (s.rewardsStartTime != 0) {
            s.lastIntervalBurnTime = s.rewardsStartTime;
        }
    }
}
