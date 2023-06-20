// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IDenominatedOracleFactory is IAuthorizable {
  // --- Events ---
  event NewDenominatedOracle(
    address indexed _denominatedOracle, IBaseOracle _priceSource, IBaseOracle _denominationPriceSource, bool _inverted
  );

  // --- Methods ---
  function deployDenominatedOracle(
    IBaseOracle _priceSource,
    IBaseOracle _denominationPriceSource,
    bool _inverted
  ) external returns (address _denominatedOracle);

  // --- Views ---
  function denominatedOraclesList() external view returns (address[] memory _denominatedOraclesList);
}
