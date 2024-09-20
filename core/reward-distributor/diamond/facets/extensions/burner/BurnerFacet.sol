// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AppStorage, Burn} from "../../../libraries/LibAppStorage.sol";
import {LibDiamond} from "../../../libraries/LibDiamond.sol";
import {IERC20Burnable} from "../../../../../token/extensions/IERC20Burnable.sol";
import "../../../libraries/LibHelpers.sol";

contract BurnerFacet {
    AppStorage internal s;

    function burn(uint256 amount) public {
        LibDiamond.enforceIsContractOwner();

        require(amount > 0, "BurnerFacet: cannot burn 0 tokens");

        uint256 releasable = LibHelpers.releasableToken(s.rewardsToken, s.totalPendingRewards);
        require(amount <= releasable, "BurnerFacet: cannot burn more tokens than are available for distribution");

        s.burns.push(Burn(amount, block.timestamp));
        IERC20Burnable(address(s.rewardsToken)).burn(amount);
        
        // If this burn removes all of the token, kill distributions immediately
        if (amount == releasable) {
          s.totalRewardsPerSecond = 0;
        }
    }

    function burnMax() public {
        LibDiamond.enforceIsContractOwner();
        uint256 releasable = LibHelpers.releasableToken(s.rewardsToken, s.totalPendingRewards);
        burn(releasable);
    }

    function addExternalBurn(uint256 amount, uint256 timestamp) public {
        LibDiamond.enforceIsContractOwner();
        s.burns.push(Burn(amount, timestamp));
    }
}
