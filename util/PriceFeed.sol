// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPriceFeed.sol";

contract PriceFeed is Ownable, IPriceFeed {
    /// @dev decimals offset for the dollar price values
    uint256 public decimals = 8;

    mapping(address => uint256) private prices;

    function setPrice(address token, uint256 newPrice) public onlyOwner {
        prices[token] = newPrice;
    }

    function setPrices(
        address[] memory tokens,
        uint256[] memory newPrices
    ) external onlyOwner {
        require(
            tokens.length == newPrices.length,
            "PriceFeed: token and price array lengths must match"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            setPrice(tokens[i], newPrices[i]);
        }
    }

    function getPrice(address token) external view returns (uint256) {
        require(prices[token] != 0, "PriceFeed: no price found for address");
        return prices[token];
    }
}
