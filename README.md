# iN8 DAO Smart Contracts

This repository contains the smart contracts for the iN8 DAO.

## Contracts

All the implementations are in the `projects/in8` folder, with the core logic for these contracts in the `core` folder.

- `projects/in8/In8Governor.sol`: The governor contract for the iN8 DAO.
- `projects/in8/In8Nft.sol`: The ERC721 nft contract for the iN8 DAO.
- `projects/in8/in8Token.sol`: The ERC20 token contract for the iN8 DAO.
- `projects/in8/in8RewardDistributorDiamond.sol`: The reward distributor contract for the iN8 DAO.

### Governor

The governor contract is a modified version of the upgradeable [governor contract](https://docs.openzeppelin.com/contracts/4.x/governance) from OpenZeppelin. We removed the delegation functionality and updated the proposal creation logic to fit the needs of the In8 DAO.

### NFT

The NFT contracts is an implementation of the upgradable [ERC721](https://docs.openzeppelin.com/contracts/4.x/erc721) from OpenZeppelin. We added additional functionality to fit the needs of the In8 DAO.

### Token

The token contract is an implementation of the [ERC20](https://docs.openzeppelin.com/contracts/4.x/erc20) from OpenZeppelin. The token is deflationary, meaning that every time the token is transferred, an additional 10% of the transfer amount is burned.

### Reward Distributor

The reward distributor is an implementation of the [diamond pattern](https://eips.ethereum.org/EIPS/eip-2535). This contract is used to distribute rewards to the In8 DAO based on NFT ownership and participation in the DAO. Additional diamond resources can be found [here](https://github.com/mudgen/awesome-diamonds).
