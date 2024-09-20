// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIntervalBurner {
    event IntervalBurn(uint256 amount);

    function intervalBurn() external;

    function lastIntervalBurnTime() external view returns (uint256);
}
