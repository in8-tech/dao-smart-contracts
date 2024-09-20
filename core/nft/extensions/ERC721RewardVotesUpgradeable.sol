// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
// import {ERC721VotesNoDelegationUpgradeable} from "./ERC721VotesNoDelegationUpgradeable.sol";
// import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {INftStaker} from "../interfaces/INftStaker.sol";

// abstract contract VotingNft is
//     ERC721Upgradeable,
//     ERC721VotesNoDelegationUpgradeable,
//     UUPSUpgradeable
// {
//     INftStaker private staker;

//     /**
//      * @dev Returns the balance of `account`.
//      */
//     function _getVotingUnits(
//         address account
//     ) internal view virtual override returns (uint256) {
//         if (address(staker) == address(0)) {
//             return balanceOf(account);
//         } else if (account == address(staker)) {
//             return 0;
//         } else {
//             return staker.stakedBalanceOf(account) + balanceOf(account);
//         }
//     }

//     function _afterTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId,
//         uint256 batchSize
//     ) internal override(ERC721Upgradeable, ERC721VotesNoDelegationUpgradeable) {
//         super._afterTokenTransfer(from, to, tokenId, batchSize);
//     }

//     function supportsInterface(
//         bytes4 interfaceId
//     )
//         public
//         view
//         override(ERC721Upgradeable, ERC721VotesNoDelegationUpgradeable)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }
