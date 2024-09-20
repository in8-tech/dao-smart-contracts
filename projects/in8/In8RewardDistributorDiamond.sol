// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../core/reward-distributor/diamond/RewardDistributorDiamond.sol";

contract In8RewardDistributorDiamond is RewardDistributorDiamond {
    constructor(
        address _contractOwner,
        address _diamondCutFacet
    ) RewardDistributorDiamond(_contractOwner, _diamondCutFacet) {}
}
