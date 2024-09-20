// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../core/token/extensions/ERC20FeeBurnable.sol";

contract In8 is ERC20, Ownable, ERC20Pausable, ERC20Burnable, ERC20FeeBurnable {
    uint256 public initialSupply;

    constructor(uint256 initialSupply_) ERC20("iN8", "IN8") ERC20FeeBurnable() {
        initialSupply = initialSupply_;
        _mint(msg.sender, initialSupply_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable, ERC20FeeBurnable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
