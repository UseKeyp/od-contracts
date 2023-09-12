// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ICollateralJoinChild} from '@interfaces/factories/ICollateralJoinChild.sol';

interface ICollateralJoinDelegatableChild is ICollateralJoinChild {
  // --- Data ---
  /**
   * @notice Address to whom the votes are delegated
   */
  function delegatee() external view returns (address _delegatee);
}
