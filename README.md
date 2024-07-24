# DN404 Reroller

## Description

DN404 Reroller is a smart contract that allows users to reroll their desired DN404 NFT without any side effect to other collections.

### Features

- Single Reroll DN404 NFT
- Warp Reroll DN404 NFT
- [Reroll Karma](https://etherscan.io/token/0x9cd9ba6aa93401c4cda88b7d3ebef6b925fcd505)

### Reroll Karma

Reroll Karma is a token awarded to users with every reroll. While it doesn't currently have any practical use, it serves as a fun way to acknowledge your rerolls.

## Deployments

| Version                           | Address                                                                                                               |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [v1](./src/Reroller.sol)          | [0x866db0558e174e4d2c94eb1b30fab0edfbefa2c0](https://etherscan.io/address/0x866db0558e174e4d2c94eb1b30fab0edfbefa2c0) |
| [v2](./src/RerollerV2.sol)        | [0x165d918c272ce44826589b70e1223b9dae6d4c53](https://etherscan.io/address/0x165d918c272ce44826589b70e1223b9dae6d4c53) |
| [v3_1](./src/v3/RerollerV3_1.sol) | [0x1753f8ef288301b7d38dd8dcc0cc10a3b2535ba0](https://etherscan.io/address/0x1753f8ef288301b7d38dd8dcc0cc10a3b2535ba0) |

## How to use (~V2)

1. Prepare account with 1 DN404 token
2. Approve 1 DN404 token to the Reroller contract
3. Execute `reroll` function

## How to use (V3_1)

### Single Reroll

1. Transfer DN404 to the Reroller contract

### Warp Reroll

1. Transfer DN404 to the Reroller contract with desired tokenId
2. dn404.safeTransferFrom(`MY_ADDR`,`REROLLER_ADDR`,`MY_TOKEN_ID`,abi.encode(`DESIRED_TOKEN_ID`))
