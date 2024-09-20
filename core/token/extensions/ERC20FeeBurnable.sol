// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20FeeBurnable is Context, ERC20, Ownable {
    uint256 public transferFeePercentage = 10; // 10% fee

    mapping(address => bool) private _isExcludedFromIncomingFee;
    mapping(address => bool) private _isExcludedFromOutgoingFee;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _isExcludedFromIncomingFee[owner()] = true;
        _isExcludedFromOutgoingFee[owner()] = true;
        _isExcludedFromIncomingFee[address(this)] = true;
        _isExcludedFromOutgoingFee[address(this)] = true;
        _isExcludedFromIncomingFee[address(0)] = true;
        _isExcludedFromOutgoingFee[address(0)] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        _takeFeeIfRequired(from, to, value);
        super._beforeTokenTransfer(from, to, value);
    }

    /**
     * @dev Checks if `account` is excluded from incoming fees
     */
    function isExcludedFromIncomingFee(
        address account
    ) external view returns (bool) {
        return _isExcludedFromIncomingFee[account];
    }

    /**
     * @dev Checks if `account` is excluded from outgoing fees
     */
    function isExcludedFromOutgoingFee(
        address account
    ) external view returns (bool) {
        return _isExcludedFromOutgoingFee[account];
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromIncomingFee`
     */
    function excludeFromIncomingFee(address account) external onlyOwner {
        _excludeFromIncomingFee(account);
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromIncomingFee`
     */
    function includeInIncomingFee(address account) external onlyOwner {
        _includeInIncomingFee(account);
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromOutgoingFee`
     */
    function excludeFromOutgoingFee(address account) external onlyOwner {
        _excludeFromOutgoingFee(account);
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromOutgoingFee`
     */
    function includeInOutgoingFee(address account) external onlyOwner {
        _includeInOutgoingFee(account);
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromIncomingFee`
     */
    function _excludeFromIncomingFee(address account) private {
        _isExcludedFromIncomingFee[account] = true;
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromIncomingFee`
     */
    function _includeInIncomingFee(address account) private {
        _isExcludedFromIncomingFee[account] = false;
    }

    /**
     * @dev Sets true value for `account` in `_isExcludedFromOutgoingFee`
     */
    function _excludeFromOutgoingFee(address account) private {
        _isExcludedFromOutgoingFee[account] = true;
    }

    /**
     * @dev Sets false value for `account` in `_isExcludedFromOutgoingFee`
     */
    function _includeInOutgoingFee(address account) private {
        _isExcludedFromOutgoingFee[account] = false;
    }

    /**
     * @dev Assess and transfer the transaction fee.
     */
    function _takeFeeIfRequired(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (_shouldTakeFee(sender, recipient)) {
            uint256 burnFee = (amount * transferFeePercentage) / 100;
            require(
                balanceOf(sender) >= amount + burnFee,
                "ERC20FeeBurnable: transfer amount + fees exceeds balance"
            );
            _burn(sender, burnFee);
        }
    }

    /**
     * @dev Checks if a fee should be taken from the transaction.
     */
    function _shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return
            !_isExcludedFromIncomingFee[recipient] &&
            !_isExcludedFromOutgoingFee[sender];
    }
}
