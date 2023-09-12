// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {CTypeBase} from '@script/postdeployment/base/CTypeBase.s.sol';

// BROADCAST
// source .env && forge script GetCTypes --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_GOERLI_RPC --broadcast --verify --etherscan-api-key $ARB_ETHERSCAN_API_KEY

// SIMULATE
// source .env && forge script GetCTypes --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_GOERLI_RPC

contract GetCTypes is CTypeBase {
  function run() public {
    vm.startBroadcast(vm.envUint('ARB_GOERLI_PK'));
    bytes32[] memory CTypes = collateralJoinFactory.collateralTypesList();
    bytes32[] memory CTypesForCollatAuction = collateralAuctionHouseFactory.collateralList();
    vm.stopBroadcast();
  }
}

/**
 * example output:
 *
 * 0000000000000000000000000000000000000000000000000000000000000020 // each item is 32 (0x20) bytes
 * 0000000000000000000000000000000000000000000000000000000000000005 // 5 items
 * 5745544800000000000000000000000000000000000000000000000000000000 // WETH
 * 4654524700000000000000000000000000000000000000000000000000000000 // FTRG
 * 5742544300000000000000000000000000000000000000000000000000000000 // WBTC
 * 53544f4e45530000000000000000000000000000000000000000000000000000 // STONES
 * 544f54454d000000000000000000000000000000000000000000000000000000 // TOTEM
 */
