// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRoyalties is IERC165 {
  
  event RoyaltiesUpdated(
    uint256 indexed tokenId,
    address payable receiver,
    uint256 basisPoints
  );

  /**
   * @dev Get royalites of a token via EIP-2981 Standard
   */
  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}
