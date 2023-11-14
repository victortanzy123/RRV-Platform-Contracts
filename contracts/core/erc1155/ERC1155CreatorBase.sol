// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./ERC1155Core.sol";
import "./IERC1155CreatorBase.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract ERC1155CreatorBase is ERC1155Core, IERC1155CreatorBase, ReentrancyGuard {
  using Strings for uint256;

  uint256 internal _tokenCount = 0;

  mapping(uint256 => TokenMetadataConfig) internal _tokenMetadata;


  /**
   *  @dev EIP-2981
   *
   * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
   *
   * => 0x2a55205a = 0x2a55205a
   */
  bytes4 private constant INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

  modifier isExistingToken(uint256 tokenId) {
    require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");
    _;
  }

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Core, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155CreatorBase).interfaceId ||
      interfaceId == INTERFACE_ID_ROYALTIES_EIP2981;
  }

  /**
   * @dev See {IERC1155CreatorBase-updateTokenURI}.
   */
  function updateTokenURI(uint256 tokenId, string calldata uri) external virtual {
    _setTokenURI(tokenId, uri);
  }

  /**
   * @dev See {IERC1155CreatorBase-updateTokenClaimStatus}.
   */
  function updateTokenClaimStatus(uint256 tokenId, TokenClaimType claimStatus) external virtual {
    _setTokenClaimStatus(tokenId, claimStatus);
  }

  /**
   * @dev See {IERC1155CreatorBase-updateTokenURI}.
   */
  function setRoyalties(
    uint256 tokenId,
    address payable receiver,
    uint16 basisPoints
  ) external virtual {
    _setRoyalties(tokenId, receiver, basisPoints);
  }

  /**
   * @dev Set token uri for an existing tokenId.
   */
  function _setTokenURI(uint256 tokenId, string calldata uri)
    internal
    virtual
    isExistingToken(tokenId)
  {
    _tokenMetadata[tokenId].uri = uri;
  }

  /**
   * @dev Set new public mint price for an existing tokenId.
   */
  function _setTokenMintPrice(uint256 tokenId, uint256 newPrice)
    internal
    virtual
    isExistingToken(tokenId)
  {
    _tokenMetadata[tokenId].price = newPrice;
  }

  /**
   * @dev Set claim status for an existing tokenId.
   */
  function _setTokenClaimStatus(uint256 tokenId, TokenClaimType claimStatus)
    internal
    virtual
    isExistingToken(tokenId)
  {
    _tokenMetadata[tokenId].claimStatus = claimStatus;

    emit TokenClaimStatusUpdate(tokenId, claimStatus);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   */
  function uri(uint256 id) external view returns (string memory tokenURI) {
    tokenURI = _tokenURI(id);
  }

  /**
   * @dev See {IERC1155CreatorBase-totalSupply}.
   */
  function totalSupply(uint256 tokenId)
    external
    view
    isExistingToken(tokenId)
    returns (uint256 totalSupply)
  {
    totalSupply = _tokenMetadata[tokenId].totalSupply;
  }

  /**
   * @dev See {IERC1155CreatorBase-maxSupply}.
   */
  function maxSupply(uint256 tokenId)
    external
    view
    isExistingToken(tokenId)
    returns (uint256 maxSupply)
  {
    maxSupply = _tokenMetadata[tokenId].maxSupply;
  }

  /**
   * @dev See {IERC1155CreatorBase-publicMintPrice}.
   */
  function publicMintPrice(uint256 tokenId)
    external
    view
    isExistingToken(tokenId)
    returns (uint256 mintPrice)
  {
    mintPrice = _tokenMetadata[tokenId].price;
  }

  /**
   * @dev See {IERC1155CreatorBase-publicMintPrice}.
   */
  function updateTokenMintPrice(uint256 tokenId, uint256 newPrice) external {
    _tokenMetadata[tokenId].price = newPrice;
  }

  /**
   * @dev See {IERC1155CreatorBase-tokenMetadata}.
   */
  function tokenMetadata(uint256 tokenId)
    external
    view
    isExistingToken(tokenId)
    returns (
      uint256 totalSupply,
      uint256 maxSupply,
      uint256 mintPrice,
      uint256 maxClaimPerUser,
      string memory uri,
      TokenClaimType claimStatus
    )
  {
    TokenMetadataConfig memory tokenMetadata = _tokenMetadata[tokenId];
    totalSupply = tokenMetadata.totalSupply;
    maxSupply = tokenMetadata.maxSupply;
    mintPrice = tokenMetadata.price;
    maxClaimPerUser = tokenMetadata.maxClaimPerUser;
    uri = tokenMetadata.uri;
    claimStatus = tokenMetadata.claimStatus;
  }

  /**
   * @dev Retrieve an existing token's URI
   */
  function _tokenURI(uint256 tokenId)
    internal
    view
    isExistingToken(tokenId)
    returns (string memory uri)
  {
    uri = _tokenMetadata[tokenId].uri;
  }


  /**
   * @dev See {IERC1155CreatorCore-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 value)
    external
    view
    virtual
    override
    returns (address receiver, uint256 bps)
  {
    (receiver, bps) = _getRoyaltyInfo(tokenId, value);
  }


  function _getRoyaltyInfo(uint256 tokenId, uint256 value)
    internal
    view
    returns (address receiver, uint256 amount)
  {
    RoyaltyConfig memory royalties = _tokenMetadata[tokenId].royalties;
    receiver = royalties.receiver;
    amount = (royalties.bps * value) / 10000;
  }

  /**
   * Set royalties for a token
   */
  function _setRoyalties(
    uint256 tokenId,
    address payable receiver,
    uint16 basisPoints
  ) internal {
    _checkRoyalties(receiver, basisPoints);
    delete _tokenMetadata[tokenId].royalties;
    _updateRoyaltiesInfo(tokenId, receiver, basisPoints);
  }

  /**
   * Helper function to set royalties
   */
  function _updateRoyaltiesInfo(
    uint256 tokenId,
    address payable receiver,
    uint16 basisPoints
  ) private {
    RoyaltyConfig memory updatedRoyalties = RoyaltyConfig({
        receiver: receiver,
        bps: basisPoints
    });
    _tokenMetadata[tokenId].royalties = updatedRoyalties;
    emit RoyaltiesUpdated(tokenId, receiver, basisPoints);
  }

  /**
   * Helper function to check that royalties provided are valid
   */
  function _checkRoyalties(address payable receiver, uint16 basisPoints)
    private
    pure
  {
    require(receiver != address(0), "Null address");
    require(basisPoints < 10000, "Invalid total royalties");
  }
}
