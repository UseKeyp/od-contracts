// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Script} from 'forge-std/Script.sol';
import {GoerliContracts} from '@script/GoerliContracts.s.sol';
import {ARB_GOERLI_WETH} from '@script/Registry.s.sol';

import {DenominatedOracleFactory} from '@contracts/factories/DenominatedOracleFactory.sol';
import {UniV3RelayerFactory} from '@contracts/factories/UniV3RelayerFactory.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

contract OracleBase is GoerliContracts, Script {
  UniV3RelayerFactory public uniV3RelayerFactory = UniV3RelayerFactory(uniV3RelayerFactoryAddr);
  DenominatedOracleFactory public denominatedOracleFactory = DenominatedOracleFactory(denominatedOracleFactoryAddr);

  address public OD_token = systemCoinAddr;
  address public ODG_token = protocolTokenAddr;
  address public WETH_token = ARB_GOERLI_WETH;

  uint24 public fee = uint24(0xbb8);
  uint32 public period = uint32(1 days);

  IBaseOracle public od_weth_UniV3Relayer;
  IBaseOracle public odg_weth_UniV3Relayer;
  IBaseOracle public weth_usd_denominatedOracle;
  IBaseOracle public totem_weth_denominatedOracle;
}
