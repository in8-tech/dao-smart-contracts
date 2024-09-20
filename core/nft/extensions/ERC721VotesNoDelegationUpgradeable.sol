// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./VotesNoDelegationUpgradeable.sol";
import "../interfaces/INftStaker.sol";

/**
 * @dev Extension of ERC721 to support voting without delegation. Votes are counted immediately upon minting.
 */
abstract contract ERC721VotesNoDelegationUpgradeable is
    Initializable,
    ERC721Upgradeable,
    VotesNoDelegationUpgradeable,
    AccessControlUpgradeable
{
    function __ERC721VotesNoDelegation_init() internal onlyInitializing {}

    function __ERC721VotesNoDelegation_init_unchained()
        internal
        onlyInitializing
    {}

    address public staker;

    // clock() and CLOCK_MODE() are needed to enable timestamp based voting instead of block based
    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    /**
     * @dev See {ERC721-_afterTokenTransfer}. Adjusts votes when tokens are transferred, ignoring the staker contract.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        // Ignore transfers to and from the staker contract
        if (from != staker && to != staker) {
            uint256 amount = batchSize; // Each token is 1 voting unit
            _transferVotingUnits(from, to, amount);
        }
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev Returns the voting units of `account`, including staked NFTs.
     */
    function _getVotingUnits(
        address account
    ) internal view virtual override returns (uint256) {
        if (account == staker) {
            return 0;
        }
        // Add the stakedBalanceOf(account) to the balanceOf(account)
        return balanceOf(account) + INftStaker(staker).stakedBalanceOf(account);
    }

    function setStaker(address _staker) external onlyRole(DEFAULT_ADMIN_ROLE) {
        staker = _staker;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}
