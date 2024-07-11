// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import '@script/Registry.s.sol';
import {Common} from '@test/e2e/Common.t.sol';

contract E2ETestSpecsTrue is Common {
  function setUp() public virtual override {
    _isCastTokens = true;
    super.setUp();
  }

  function testCastTokens() public {
    assertEq(address(systemCoin), MAINNET_SYSTEM_COIN);
    assertEq(address(protocolToken), MAINNET_PROTOCOL_TOKEN);
  }
}

contract E2ETestSpecsFalse is Common {
  function setUp() public virtual override {
    super.setUp();
  }

  function testCastTokens() public {
    assertNotEq(address(systemCoin), MAINNET_SYSTEM_COIN);
    assertNotEq(address(protocolToken), MAINNET_PROTOCOL_TOKEN);
  }
}
