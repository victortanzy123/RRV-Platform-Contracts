// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../erc1155/ERC1155CreatorBase.sol";
import "./IRRVCreator.sol";
import "../helpers/BoringOwnable.sol";
import "./TokenRevenueHelper.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RRVPlatform is
  IRRVCreator,
  ReentrancyGuard,
  ERC1155CreatorBase,
  BoringOwnable,
  TokenRevenueHelper
{
 


  mapping(uint256 => mapping(address => uint256)) internal _userTokenClaimCount;

  constructor(
    string memory name_,
    string memory symbol_,
    uint64 feeBps_
  ) ERC1155CreatorBase(name_, symbol_) TokenRevenueHelper(feeBps_) {}

  modifier checkTokenClaimable(uint256 tokenId, address user) {
    TokenClaimType claimStatus = _tokenMetadata[tokenId].claimStatus;
    require(claimStatus == TokenClaimType.PUBLIC, "Claim disabled");
    _;
  }

  /**
   * @dev See {IRRVCreator-initialiseNewSingleToken}.
   */
  function initialiseNewSingleToken(
    TokenMetadataConfig calldata tokenConfig,
    address revenueRecipient
  ) external returns (uint256 tokenId) {
    tokenId = _initialiseToken(tokenConfig, revenueRecipient);
  }

  /**
   * @dev See {IRRVCreator-initialiseNewMultipleToken}.
   */
  function initialiseNewMultipleTokens(
    TokenMetadataConfig[] calldata tokenConfigs,
    address[] calldata revenueRecipients
  ) external returns (uint256[] memory tokenIds) {
    uint256 length = tokenConfigs.length;
    tokenIds = new uint256[](length);

    for (uint256 i = 0; i < length; ) {
      uint256 tokenId = _initialiseToken(tokenConfigs[i], revenueRecipients[i]);
      tokenIds[i] = tokenId;
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Internal function to initialise a token via all the parameters of `TokenMetadataConfig` specified alongside with the `revenueRecipient` for mint fee collection.
   */
  function _initialiseToken(TokenMetadataConfig calldata tokenConfig, address revenueRecipient)
    internal
    returns (uint256 tokenId)
  {
    require(tokenConfig.totalSupply == 0, "Initial total supply should be 0");
    require(tokenConfig.maxSupply > 0, "Invalid amount");
    require(tokenConfig.maxClaimPerUser > 0, "Invalid max claim quantity");
    require(
      tokenConfig.maxClaimPerUser <= tokenConfig.maxSupply,
      "Invalid individual claim quantity"
    );

    tokenId = ++_tokenCount;

    _tokenMetadata[tokenId] = tokenConfig;
    _tokenRevenueRecipient[tokenId] = revenueRecipient;

    emit TokenInitialised(
      tokenId,
      tokenConfig.maxSupply,
      tokenConfig.price,
      tokenConfig.maxClaimPerUser,
      tokenConfig.uri,
      revenueRecipient
    );
  }

  /**
   * @dev See {IRRVCreator-mintExistingSingleToken}.
   */
  function mintExistingSingleToken(
    address receiver,
    uint256 tokenId,
    uint256 amount
  ) external payable {
    require(amount > 0, "Invalid amount");
    if (_tokenMetadata[tokenId].price > 0) {
      uint256 totalPayableAmount = _tokenMetadata[tokenId].price * amount;
      require(msg.value == totalPayableAmount, "Unmatched value sent");
      _processMintFees(tokenId, totalPayableAmount);
    }

    _mintExistingToken(tokenId, receiver, amount);
  }

  /**
   * @dev See {IRRVCreator-mintExistingMultipleToken}.
   */
  function mintExistingMultipleTokens(
    address[] calldata receivers,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external payable {
    require(
      receivers.length == tokenIds.length && tokenIds.length == amounts.length,
      "Invalid inputs"
    );
    uint256 length = receivers.length;
    uint256 totalPayableAmount;
    uint256[] memory payableAmounts = new uint256[](length);
    for (uint256 i = 0; i < length; ) {
        uint256 payableAmount = _tokenMetadata[tokenIds[i]].price * amounts[i];
        totalPayableAmount += payableAmount;
        payableAmounts[i] = payableAmount;
        unchecked {
          i++;
        }
      }
    require(msg.value == totalPayableAmount, "Unmatched value sent");
    _batchProcessMintFees(tokenIds, payableAmounts);

    for (uint256 i = 0; i < length; ) {
      require(amounts[i] > 0, "Invalid amount");
      _mintExistingToken(tokenIds[i], receivers[i], amounts[i]);
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Internal function to process minting of a valid `tokenId` with the specified `amount` and `receiver`.
   */
  function _mintExistingToken(
    uint256 tokenId,
    address receiver,
    uint256 amount
  ) internal nonReentrant checkTokenClaimable(tokenId, msg.sender) {
    require(tokenId <= _tokenCount, "Invalid tokenId specified");
    require(
      _tokenMetadata[tokenId].totalSupply + amount <= _tokenMetadata[tokenId].maxSupply,
      "Invalid amount specified"
    );
    require(
      _userTokenClaimCount[tokenId][receiver] + amount <= _tokenMetadata[tokenId].maxClaimPerUser,
      "Exceed token max claim limit"
    );

    _tokenMetadata[tokenId].totalSupply += amount;
    _userTokenClaimCount[tokenId][receiver] += amount;
    _mint(receiver, tokenId, amount, "");

    emit TokenMint(tokenId, amount, receiver, msg.sender, _tokenMetadata[tokenId].price * amount);
  }

  /**
   * @dev Set token uri after a token is minted by permissioned user.
   */
  function updateTokenURI(uint256 tokenId, string calldata uri)
    external
    override(ERC1155CreatorBase, IERC1155CreatorBase)
    onlyOwner
  {
    _setTokenURI(tokenId, uri);
  }

  /**
   * @dev Set token uri after a token is minted by permissioned user.
   */
  function updateTokenClaimStatus(uint256 tokenId, TokenClaimType claimStatus)
    external
    override(ERC1155CreatorBase, IERC1155CreatorBase)
    onlyOwner
  {
    _setTokenClaimStatus(tokenId, claimStatus);
  }

  /**
   * @dev Set secondary royalties for a particular tokenId by permissioned user.
   */
  function setRoyalties(
    uint256 tokenId,
    address payable receiver,
    uint16 basisPoints
  ) external override(ERC1155CreatorBase, IERC1155CreatorBase) onlyOwner {
    _setRoyalties(tokenId, receiver, basisPoints);
  }

  /**
   * @dev See {IRRVCreator-updateTokenRevenueRecipient}.
   */
  function updateTokenRevenueRecipient(uint256 tokenId, address newRecipient)
    external override(TokenRevenueHelper)
    isExistingToken(tokenId)
    onlyOwner
  {
    require(newRecipient != address(0), "Null address");
    _tokenRevenueRecipient[tokenId] = newRecipient;

    emit TokenRevenueRecipientUpdate(tokenId, newRecipient);
  }

  /**
   * @dev See {TokenRevenueHelper-updatePlatformFeeBps}.
   */
  function updatePlatformFeeBps(uint64 bps) external override(TokenRevenueHelper) onlyOwner {
    require(bps < MAX_BPS, "Invalid basis points");
    PLATFORM_FEE_BPS = bps;
  }

   /**
   * @dev See {TokenRevenueHelper-updateArtzoneFeeBps}.
   */
   function tokenAmountClaimedByUser(uint256 tokenId, address recipient) external view returns (uint256) {
      return _userTokenClaimCount[tokenId][recipient];
   }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155CreatorBase, IERC165)
    returns (bool)
  {
    return super.supportsInterface(interfaceId) ||
      ERC1155CreatorBase.supportsInterface(interfaceId);
  }

  /**
   * @dev See {TokenRevenueHelper-collectPlatformFees}.
   */
  function collectPlatformFees(address recipient) external override(TokenRevenueHelper) payable onlyOwner {
    payable(recipient).transfer(address(this).balance);
  }

  /// @dev Lets the contract receives native tokens from `nativeTokenWrapper` withdraw.
  receive() external payable {}
}
