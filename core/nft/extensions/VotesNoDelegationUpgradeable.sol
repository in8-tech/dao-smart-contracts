// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC5805Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CheckpointsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Modified Votes contract without delegation. Votes are counted directly based on the account's balance.
 */
abstract contract VotesNoDelegationUpgradeable is
    Initializable,
    ContextUpgradeable,
    EIP712Upgradeable,
    IERC5805Upgradeable
{
    function __VotesNoDelegation_init() internal onlyInitializing {}

    function __VotesNoDelegation_init_unchained() internal onlyInitializing {}

    using CheckpointsUpgradeable for CheckpointsUpgradeable.Trace224;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Mapping from account to checkpoints
    mapping(address => CheckpointsUpgradeable.Trace224)
        private _accountCheckpoints;

    // Total supply of votes checkpoints
    CheckpointsUpgradeable.Trace224 private _totalCheckpoints;

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(
        address account
    ) public view virtual override returns (uint256) {
        return _accountCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at a specific timepoint in the past.
     */
    function getPastVotes(
        address account,
        uint256 timepoint
    ) public view virtual override returns (uint256) {
        require(timepoint < clock(), "Votes: future lookup");
        return
            _accountCheckpoints[account].upperLookupRecent(
                SafeCastUpgradeable.toUint32(timepoint)
            );
    }

    /**
     * @dev Returns the total supply of votes available at a specific timepoint in the past.
     */
    function getPastTotalSupply(
        uint256 timepoint
    ) public view virtual override returns (uint256) {
        require(timepoint < clock(), "Votes: future lookup");
        return
            _totalCheckpoints.upperLookupRecent(
                SafeCastUpgradeable.toUint32(timepoint)
            );
    }

    /**
     * @dev Clock used for flagging checkpoints. Uses block number by default.
     */
    function clock() public view virtual override returns (uint48) {
        return SafeCastUpgradeable.toUint48(block.number);
    }

    /**
     * @dev Machine-readable description of the clock as specified in EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory) {
        // Check that the clock was not modified
        require(clock() == block.number, "Votes: broken clock mode");
        return "mode=blocknumber&from=default";
    }

    /**
     * @dev Returns the delegate that `account` has chosen. Each account is its own delegate in this model.
     */
    function delegates(
        address account
    ) public view virtual override returns (address) {
        return account;
    }

    // Remove delegate and delegateBySig functions as delegation is disabled
    function delegate(address) public virtual override {
        revert("VotesNoDelegation: delegation is disabled");
    }

    function delegateBySig(
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) public virtual override {
        revert("VotesNoDelegation: delegation is disabled");
    }

    /**
     * @dev Transfers, mints, or burns voting units. Adjusts votes directly without delegation.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            _push(
                _totalCheckpoints,
                _add,
                SafeCastUpgradeable.toUint224(amount)
            );
        }
        if (to == address(0)) {
            _push(
                _totalCheckpoints,
                _subtract,
                SafeCastUpgradeable.toUint224(amount)
            );
        }

        if (from != address(0)) {
            (uint256 oldValue, uint256 newValue) = _push(
                _accountCheckpoints[from],
                _subtract,
                SafeCastUpgradeable.toUint224(amount)
            );
            emit DelegateVotesChanged(from, oldValue, newValue);
        }

        if (to != address(0)) {
            (uint256 oldValue, uint256 newValue) = _push(
                _accountCheckpoints[to],
                _add,
                SafeCastUpgradeable.toUint224(amount)
            );
            emit DelegateVotesChanged(to, oldValue, newValue);
        }
    }

    function _push(
        CheckpointsUpgradeable.Trace224 storage store,
        function(uint224, uint224) pure returns (uint224) op,
        uint224 delta
    ) private returns (uint224, uint224) {
        return
            store.push(
                SafeCastUpgradeable.toUint32(clock()),
                op(store.latest(), delta)
            );
    }

    function _add(uint224 a, uint224 b) private pure returns (uint224) {
        return a + b;
    }

    function _subtract(uint224 a, uint224 b) private pure returns (uint224) {
        return a - b;
    }

    /**
     * @dev Must return the voting units held by an account.
     */
    function _getVotingUnits(
        address account
    ) internal view virtual returns (uint256);

    uint256[46] private __gap;
}
