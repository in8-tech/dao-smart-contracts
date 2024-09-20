// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721EnumerableTyped is IERC721Enumerable {
    enum NftType {
        Founder,
        Ambassador
    }

    function getNftType(uint256 tokenId) external view returns (NftType);
}
