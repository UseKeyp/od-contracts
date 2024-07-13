// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {ISAFESaviour} from '@interfaces/external/ISAFESaviour.sol';

contract SafeSaviourForForTest is ISAFESaviour {
  constructor() {}

  function saveSAFE(
    address,
    bytes32,
    address
  ) external pure returns (bool _ok, uint256 _collateralAdded, uint256 _liquidatorReward) {
    _ok = true;
    _collateralAdded = type(uint256).max;
    _liquidatorReward = type(uint256).max;
  }
}
