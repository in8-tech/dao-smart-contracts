// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPrice {
    uint256 constant PRICE_PRECISION = 1e12;

    function calculatePrice(
        uint256 costUsd,
        uint256 marketValue,
        uint256 marketValueDecimals,
        uint256 tokenDecimals
    ) internal pure returns (uint256) {
        uint256 dollarOfTokens = ((PRICE_PRECISION * 10 ** tokenDecimals) /
            marketValue) * 10 ** marketValueDecimals;

        return (costUsd * dollarOfTokens) / PRICE_PRECISION;
    }
}
