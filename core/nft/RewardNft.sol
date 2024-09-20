// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./extensions/ERC721VotesNoDelegationUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract RewardNft is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721VotesNoDelegationUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public maxSupply;
    uint256 public founderMax;
    uint256 public ambassadorMax;
    string public contractURI;
    string private baseURI;
    Counters.Counter private _tokenIdCounter;
    uint256 public ambassadorMintCost;
    uint256 public founderMintCost;
    IERC20 public paymentToken;
    address public paymentAddress;
    bool public isPaymentEnabled;
    bool public isMintingEnabled;

    enum NftType {
        Founder,
        Ambassador
    }

    mapping(uint256 => NftType) private _nftTypes;
    mapping(NftType => uint256) private _nftTypeCounts;
    mapping(address => mapping(NftType => uint256)) private mintingWhitelist;

    function __RewardNft_init(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 founderMax_,
        uint256 ambassadorMax_,
        string memory baseURI_,
        string memory contractURI_,
        address paymentAddress_,
        address paymentToken_,
        uint256 ambassadorMintCost_,
        uint256 founderMintCost_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ERC721VotesNoDelegation_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        require(
            founderMax_ + ambassadorMax_ == maxSupply_,
            "RewardNft: Invalid max supply distribution"
        );

        setBaseURI(baseURI_);
        setContractURI(contractURI_);
        maxSupply = maxSupply_;
        founderMax = founderMax_;
        ambassadorMax = ambassadorMax_;
        paymentAddress = paymentAddress_;
        paymentToken = IERC20(paymentToken_);
        ambassadorMintCost = ambassadorMintCost_;
        founderMintCost = founderMintCost_;
        isPaymentEnabled = true;
        isMintingEnabled = true;
    }

    function setMaxSupply(
        uint256 _maxSupply,
        uint256 _founderMax,
        uint256 _ambassadorMax
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _founderMax + _ambassadorMax == _maxSupply,
            "RewardNft: Invalid max supply distribution"
        );
        maxSupply = _maxSupply;
        founderMax = _founderMax;
        ambassadorMax = _ambassadorMax;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(
        string memory baseURI_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }

    function setContractURI(
        string memory contractURI_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = contractURI_;
    }

    function setPaymentAddress(
        address paymentAddress_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentAddress = paymentAddress_;
    }

    function setPaymentToken(
        address paymentToken_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentToken = IERC20(paymentToken_);
    }

    function setAmbassadorMintCost(
        uint256 ambassadorMintCost_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ambassadorMintCost = ambassadorMintCost_;
    }

    function setFounderMintCost(
        uint256 founderMintCost_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        founderMintCost = founderMintCost_;
    }

    function setIsPaymentEnabled(
        bool isPaymentEnabled_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isPaymentEnabled = isPaymentEnabled_;
    }

    function setIsMintingEnabled(
        bool isMintingEnabled_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintingEnabled = isMintingEnabled_;
    }

    function safeMintBatch(
        address to,
        uint256 numberToMint,
        NftType nftType
    ) public onlyRole(MINTER_ROLE) {
        _safeMintBatch(to, numberToMint, nftType);
    }

    function safeMintBatchWhitelist(
        address to,
        uint256 numberToMint,
        NftType nftType
    ) public {
        require(
            mintingWhitelist[to][nftType] >= numberToMint,
            "RewardNft: not enough whitelist allowance"
        );
        _safeMintBatch(to, numberToMint, nftType);
        mintingWhitelist[to][nftType] -= numberToMint;
    }

    function safeMintBatchPayment(
        address to,
        uint256 numberToMint,
        NftType nftType
    ) public payable {
        require(isPaymentEnabled, "RewardNft: payment is not enabled");
        _safeMintBatch(to, numberToMint, nftType);
        uint256 mintCost = nftType == NftType.Founder
            ? founderMintCost
            : ambassadorMintCost;
        uint256 totalCost = mintCost * numberToMint;
        paymentToken.safeTransferFrom(msg.sender, paymentAddress, totalCost);
    }

    function _safeMintBatch(
        address to,
        uint256 amount,
        NftType nftType
    ) private {
        require(isMintingEnabled, "RewardNft: minting is not enabled");
        for (uint256 i = 0; i < amount; i++) {
            _safeMintNft(to, nftType);
        }
    }

    function _safeMintNft(address to, NftType nftType) private {
        require(totalSupply() < maxSupply, "RewardNft: max supply reached");
        if (nftType == NftType.Founder) {
            require(
                _nftTypeCounts[NftType.Founder] < founderMax,
                "RewardNft: founder max reached"
            );
        } else {
            require(
                _nftTypeCounts[NftType.Ambassador] < ambassadorMax,
                "RewardNft: ambassador max reached"
            );
        }

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _nftTypes[tokenId] = nftType;
        _nftTypeCounts[nftType]++;
    }

    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenList[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenList;
    }

    function tokensOfOwnerSubset(
        address _owner,
        uint256 _startIndex,
        uint256 _pageSize
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        require(
            _startIndex < tokenCount,
            "RewardNft: start index out of bounds"
        );

        uint256 endIndex = (_startIndex + _pageSize) > tokenCount
            ? tokenCount
            : (_startIndex + _pageSize);
        uint256[] memory tokenIds = new uint256[](endIndex - _startIndex);
        for (uint256 i = _startIndex; i < endIndex; i++) {
            tokenIds[i - _startIndex] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _burn(uint256 tokenId) internal virtual override {
        NftType nftType = _nftTypes[tokenId];
        _nftTypeCounts[nftType]--;
        delete _nftTypes[tokenId];
        super._burn(tokenId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721VotesNoDelegationUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721VotesNoDelegationUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintingWhitelistAllowance(
        address account
    )
        public
        view
        returns (uint256 founderAllowance, uint256 ambassadorAllowance)
    {
        return (
            mintingWhitelist[account][NftType.Founder],
            mintingWhitelist[account][NftType.Ambassador]
        );
    }

    function incrementMintingWhitelistAllowance(
        address account,
        uint256 amount,
        NftType nftType
    ) public onlyRole(MINTER_ROLE) {
        mintingWhitelist[account][nftType] += amount;
    }

    function decrementMintingWhitelistAllowance(
        address account,
        uint256 amount,
        NftType nftType
    ) public onlyRole(MINTER_ROLE) {
        mintingWhitelist[account][nftType] -= amount;
    }

    function getNftType(uint256 tokenId) public view returns (NftType) {
        require(_exists(tokenId), "RewardNft: token does not exist");
        return _nftTypes[tokenId];
    }

    function balanceOfByType(
        address account
    ) public view returns (uint256 founderBalance, uint256 ambassadorBalance) {
        uint256[] memory tokenIds = tokensOfOwner(account);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (getNftType(tokenIds[i]) == NftType.Founder) {
                founderBalance++;
            } else {
                ambassadorBalance++;
            }
        }
        return (founderBalance, ambassadorBalance);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
