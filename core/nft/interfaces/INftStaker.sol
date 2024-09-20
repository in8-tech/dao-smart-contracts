// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftStaker {
    /**
     * @dev View function to get the number of staked NFTs for a given user.
     * @param account The address of the user account to check staked NFTs.
     * @return The number of staked NFTs for the given user.
     */
    function stakedBalanceOf(address account) external view returns (uint256);
}
