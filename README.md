# RRV Platform Smart Contract

## Live Deployment Details

- **RRV Platform Contract Address** - `0x8ac2379b0f17138d2e83Ca87E218F810d9B6Ad63`
- **EVM Blockchain Used** - `Sepolia Testnet`
- **Chain ID** - "11155111"
- **Etherscan URL**: https://sepolia.etherscan.io/address/0x8ac2379b0f17138d2e83Ca87E218F810d9B6Ad63

## Introduction

This repository hosts the smart contract code in Solidity for RRV platform,
a one-stop avenue for digital creators and curators to create, sell and purchase digital assets in a permissionless manner via the use of smart contracts.

RRV Platform utilizes the `ERC-1155` token standard by Open Zeppelin for creators to publish their digital assets in the form of multiple semi-fungible copies. These tokens can be initialised with a fixed total supply and price for first-hand retail minting from curators.

`EIP-2918` Secondary royalties standard is also supported for all digital assets created on RRV Platform, and the revenue proceeds of all purchased digital assets will be distributed back to the creator while RRV platform takes a small percentage fee (1%) as a form of service fee.

## How to Get Started

**Step 1:** Install all relevant dependencies

```
yarn
```

**Step 2:** Create an `.env` file based off `.env.example` and fill up the respective missing values.

**Step 3:** Compile the smart contracts to generate typings for subsequent testing/deployment

```
yarn compile
```

**Step 4:** To run all test scripts

```
yarn test:rrv
```

**Step 5:** To deploy contracts (on Sepolia Testnet), make sure you have sufficient `ETH` on the testnet itself

```
yarn deploy:sepolia
```
