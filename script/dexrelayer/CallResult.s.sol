// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import '@script/Registry.s.sol';
import {Script} from 'forge-std/Script.sol';
import {FixedPointMathLib} from '@isolmate/utils/FixedPointMathLib.sol';
import {IAlgebraFactory} from '@cryptoalgebra-core/interfaces/IAlgebraFactory.sol';
import {IAlgebraPool} from '@cryptoalgebra-core/interfaces/IAlgebraPool.sol';
import {IAlgebraMintCallback} from '@cryptoalgebra-core/interfaces/callback/IAlgebraMintCallback.sol';
import {CamelotRelayerFactory} from '@contracts/factories/CamelotRelayerFactory.sol';
import {ICamelotRelayer} from '@interfaces/oracles/ICamelotRelayer.sol';
import {DenominatedOracleFactory} from '@contracts/factories/DenominatedOracleFactory.sol';
import {ChainlinkRelayerFactory, IChainlinkRelayerFactory} from '@contracts/factories/ChainlinkRelayerFactory.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {MintableERC20} from '@contracts/for-test/MintableERC20.sol';
import {MintableVoteERC20} from '@contracts/for-test/MintableVoteERC20.sol';
import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';
import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';

// BROADCAST
// source .env && forge script CallResult --with-gas-price 2000000000 -vvvvv --rpc-url $GOERLI_RPC --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

// SIMULATE
// source .env && forge script CallResult --with-gas-price 2000000000 -vvvvv --rpc-url $GOERLI_RPC

contract CallResult is Script {
  uint256 private constant WAD = 1e18;
  uint256 private constant MINT_AMOUNT = 1_000_000 ether;
  uint256 private constant ORACLE_PERIOD = 1 seconds;

  ICamelotRelayer public camelotRelayer = ICamelotRelayer(0x27F8839C1dfe338DA95f956eFaB0a4bcd6aab568);

  function run() public {
    vm.startBroadcast(vm.envUint('GOERLI_PK'));
    camelotRelayer.getResultWithValidity();
    vm.stopBroadcast();
  }
}
