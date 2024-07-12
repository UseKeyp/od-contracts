// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import 'forge-std/Test.sol';
import '@script/Registry.s.sol';
import {OpenDollarV1Arbitrum} from '@libraries/OpenDollarV1Arbitrum.sol';
import {ISystemCoin} from '@contracts/tokens/SystemCoin.sol';
import {IProtocolToken} from '@contracts/tokens/ProtocolToken.sol';
import {ISAFEEngine} from '@contracts/SAFEEngine.sol';
import {IODSafeManager} from '@contracts/proxies/ODSafeManager.sol';
import {IVault721} from '@contracts/proxies/Vault721.sol';

contract ODLib is Test {
  ISystemCoin public systemCoin;
  IProtocolToken public protocolToken;
  ISAFEEngine public safeEngine;
  IODSafeManager public safeManager;
  IVault721 public vault721;

  function setUp() public virtual {
    systemCoin = OpenDollarV1Arbitrum.SYSTEM_COIN;
    protocolToken = OpenDollarV1Arbitrum.PROTOCOL_TOKEN;
    safeEngine = OpenDollarV1Arbitrum.SAFE_ENGINE;
    safeManager = OpenDollarV1Arbitrum.SAFE_MANANGER;
    vault721 = OpenDollarV1Arbitrum.VAULT721;
  }

  function testODLib() public {
    assertTrue(systemCoin == ISystemCoin(0x221A0f68770658C15B525d0F89F5da2baAB5f321));
    assertTrue(protocolToken == IProtocolToken(MAINNET_PROTOCOL_TOKEN));
    assertTrue(safeEngine == ISAFEEngine(0xEff45E8e2353893BD0558bD5892A42786E9142F1));
    assertTrue(safeManager == IODSafeManager(0x8646CBd915eAAD1a4E2Ba5e2b67Acec4957d5f1a));
    assertTrue(vault721 == IVault721(0x0005AFE00fF7E7FF83667bFe4F2996720BAf0B36));
  }
}
