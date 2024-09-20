// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceFeed {
    function getPrice(address token) external view returns (uint256);

    function decimals() external view returns (uint256);
}
