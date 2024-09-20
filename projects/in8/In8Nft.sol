// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../../core/nft/RewardNft.sol";

contract In8 is RewardNft {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI_,
        string memory contractURI_,
        address paymentWallet_,
        address paymentToken_,
        uint256 ambassadorMintCost_,
        uint256 founderMintCost_
    ) public initializer {
        string memory name = "iN8";
        string memory symbol = "IN8";
        uint256 maxSupply = 21000;
        uint256 founderMax = 10000;
        uint256 ambassadorMax = 11000;

        __RewardNft_init(
            name,
            symbol,
            maxSupply,
            founderMax,
            ambassadorMax,
            baseURI_,
            contractURI_,
            paymentWallet_,
            paymentToken_,
            ambassadorMintCost_,
            founderMintCost_
        );
    }
}
