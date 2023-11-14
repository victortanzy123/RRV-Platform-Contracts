// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract TokenRevenueHelper is ReentrancyGuard {
    uint64 public constant MAX_BPS = 10_000;
    uint64 public PLATFORM_FEE_BPS;

    mapping(uint256 => address) internal _tokenRevenueRecipient;

    constructor(uint64 feeBps_) {
        PLATFORM_FEE_BPS = feeBps_;
    }

  /**
   * @dev Update revenue recipient for an initialised token. Can only be called by Admin.
   */
  function updateTokenRevenueRecipient(uint256 tokenId, address newRecipient) external virtual;

    /**
   * @dev Update Platform fee basis points for NFT minting sale. Can only be called by Admin.
   */
  function updatePlatformFeeBps(uint64 bps) external virtual;

  /**
   * @dev Withdraw function to withdraw fees collected from each paid NFT mint by public users to a specified recipient. To only be called by Admin.
   */
  function collectPlatformFees(address recipient) external virtual payable;

      /**
   * @dev Internal function to handle multiple processing of mint fees when `mintExistingMultipleTokens` is called via a non-permissioned user.
   */
  function _batchProcessMintFees(uint256[] calldata tokenIds, uint256[] memory payableAmounts)
    internal
  {
    for (uint256 i = 0; i < tokenIds.length; ) {
      if (payableAmounts[i] > 0) {
        _processMintFees(tokenIds[i], payableAmounts[i]);
      }
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Internal function to process mint fees and transfer outstanding payable revenue to `revenueRecipient` after deducting from Artzone's fee cut portion.
   */
  function _processMintFees(uint256 tokenId, uint256 totalPayableAmount) internal nonReentrant {
    uint256 platformFee = (totalPayableAmount * PLATFORM_FEE_BPS) / MAX_BPS;
    payable(_tokenRevenueRecipient[tokenId]).transfer(totalPayableAmount - platformFee);
  }

}