// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Script} from 'forge-std/Script.sol';
import {GoerliDeployment} from '@script/GoerliDeployment.s.sol';
import {GOVERNOR_DAO, ARB_GOERLI_WETH} from '@script/Registry.s.sol';
import {Vault721} from '@contracts/proxies/Vault721.sol';

// BROADCAST
// source .env && forge script RedeployVault721 --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_GOERLI_RPC --broadcast --verify --etherscan-api-key $ARB_ETHERSCAN_API_KEY

// SIMULATE
// source .env && forge script RedeployVault721 --with-gas-price 2000000000 -vvvvv --rpc-url $ARB_GOERLI_RPC

contract RedeployVault721 is GoerliDeployment, Script {
  function run() public {
    vm.startBroadcast(vm.envUint('ARB_GOERLI_PK'));
    vault721 = new Vault721(GOVERNOR_DAO, oracleRelayer, taxCollector, collateralJoinFactory);
    safeManager.updateVault721(address(vault721));
    vault721.updateImplementation(
      address(safeManager), address(oracleRelayer), address(taxCollector), address(collateralJoinFactory)
    );
    vm.stopBroadcast();
  }
}
