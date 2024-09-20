// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.1) (governance/Governor.sol)

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/structs/DoubleEndedQueueUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/governance/IGovernorUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";

// /**
//  * @dev Modified Governor contract to:
//  * - Remove quorum requirement.
//  * - Restrict proposal creation to specific addresses.
//  * - Allow no-op proposals.
//  */
// abstract contract GovernorNoQuorumUpgradeable is GovernorUpgradeable {
//     using DoubleEndedQueueUpgradeable for DoubleEndedQueueUpgradeable.Bytes32Deque;

//     string private _name;

//     // Mapping of addresses allowed to propose
//     mapping(address => bool) private proposers;

//     /**
//      * @dev Sets the value for {name} and {version}
//      */
//     function __GovernorNoQuorum_init(
//         string memory name_,
//         address[] memory allowedProposers
//     ) internal onlyInitializing {
//         __GovernorNoQuorum_init_unchained(name_, allowedProposers);
//     }

//     function __GovernorNoQuorum_init_unchained(
//         string memory name_,
//         address[] memory allowedProposers
//     ) internal onlyInitializing {
//         __Governor_init(name_);
//         for (uint256 i = 0; i < allowedProposers.length; i++) {
//             proposers[allowedProposers[i]] = true;
//         }
//     }

//     // ... [rest of the unchanged code] ...

//     /**
//      * @dev See {IGovernor-propose}.
//      * Modified to:
//      * - Remove quorum requirement.
//      * - Restrict proposal creation to specific addresses.
//      * - Allow no-op proposals.
//      */
//     function propose(
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas,
//         string memory description
//     ) public virtual override returns (uint256) {
//         address proposer = _msgSender();

//         // Restrict proposal creation to allowed addresses
//         require(proposers[proposer], "Governor: proposer not authorized");

//         require(
//             _isValidDescriptionForProposer(proposer, description),
//             "Governor: proposer restricted"
//         );

//         uint256 currentTimepoint = clock();
//         require(
//             getVotes(proposer, currentTimepoint - 1) >= proposalThreshold(),
//             "Governor: proposer votes below proposal threshold"
//         );

//         uint256 proposalId = hashProposal(
//             targets,
//             values,
//             calldatas,
//             keccak256(bytes(description))
//         );

//         require(
//             targets.length == values.length,
//             "Governor: invalid proposal length"
//         );
//         require(
//             targets.length == calldatas.length,
//             "Governor: invalid proposal length"
//         );
//         // Allow no-op proposals (commented out the require statement)
//         // require(targets.length > 0, "Governor: empty proposal");

//         require(
//             _proposals[proposalId].voteStart == 0,
//             "Governor: proposal already exists"
//         );

//         uint256 snapshot = currentTimepoint + votingDelay();
//         uint256 deadline = snapshot + votingPeriod();

//         _proposals[proposalId] = ProposalCore({
//             proposer: proposer,
//             voteStart: SafeCastUpgradeable.toUint64(snapshot),
//             voteEnd: SafeCastUpgradeable.toUint64(deadline),
//             executed: false,
//             canceled: false,
//             __gap_unused0: 0,
//             __gap_unused1: 0
//         });

//         emit ProposalCreated(
//             proposalId,
//             proposer,
//             targets,
//             values,
//             new string[](targets.length),
//             calldatas,
//             snapshot,
//             deadline,
//             description
//         );

//         return proposalId;
//     }

//     // ... [rest of the unchanged code] ...

//     /**
//      * @dev Override _quorumReached to always return true.
//      * This removes the quorum requirement.
//      */
//     function _quorumReached(
//         uint256 proposalId
//     ) internal view virtual override returns (bool) {
//         return true;
//     }

//     /**
//      * @dev Override _voteSucceeded to determine if "For" votes are greater than "Against" votes.
//      */
//     function _voteSucceeded(
//         uint256 proposalId
//     ) internal view virtual override returns (bool) {
//         ProposalVote storage proposalvote = _proposalVotes[proposalId];
//         return proposalvote.forVotes > proposalvote.againstVotes;
//     }

//     /**
//      * @dev Functions to manage proposers list.
//      * These functions can be called via governance proposals.
//      */

//     /**
//      * @dev Add a new proposer.
//      * Can only be called by governance (i.e., through a proposal).
//      */
//     function addProposer(address newProposer) external onlyGovernance {
//         proposers[newProposer] = true;
//     }

//     /**
//      * @dev Remove an existing proposer.
//      * Can only be called by governance (i.e., through a proposal).
//      */
//     function removeProposer(address proposerToRemove) external onlyGovernance {
//         proposers[proposerToRemove] = false;
//     }

//     // ... [rest of the unchanged code] ...

//     /**
//      * @dev Storage for proposal votes.
//      */
//     struct ProposalVote {
//         uint256 forVotes;
//         uint256 againstVotes;
//         uint256 abstainVotes;
//         mapping(address => bool) hasVoted;
//     }

//     mapping(uint256 => ProposalVote) private _proposalVotes;

//     /**
//      * @dev Get whether a voter has voted on a proposal.
//      */
//     function hasVoted(
//         uint256 proposalId,
//         address account
//     ) public view virtual override returns (bool) {
//         return _proposalVotes[proposalId].hasVoted[account];
//     }

//     /**
//      * @dev Count a vote for a proposal.
//      */
//     function _countVote(
//         uint256 proposalId,
//         address account,
//         uint8 support,
//         uint256 weight,
//         bytes memory /*params*/
//     ) internal virtual override {
//         ProposalVote storage proposalvote = _proposalVotes[proposalId];

//         require(!proposalvote.hasVoted[account], "Governor: vote already cast");
//         proposalvote.hasVoted[account] = true;

//         if (support == uint8(VoteType.Against)) {
//             proposalvote.againstVotes += weight;
//         } else if (support == uint8(VoteType.For)) {
//             proposalvote.forVotes += weight;
//         } else if (support == uint8(VoteType.Abstain)) {
//             proposalvote.abstainVotes += weight;
//         } else {
//             revert("Governor: invalid vote type");
//         }
//     }

//     /**
//      * @dev Possible vote types.
//      */
//     enum VoteType {
//         Against,
//         For,
//         Abstain
//     }

//     // ... [rest of the unchanged code] ...

//     /**
//      * @dev This empty reserved space is put in place to allow future versions to add new
//      * variables without shifting down storage in the inheritance chain.
//      */
//     uint256[45] private __gap;
// }
