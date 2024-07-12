// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {IVault721} from '@interfaces/proxies/IVault721.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {ILiquidationEngine} from '@interfaces/ILiquidationEngine.sol';
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';
import {Math, RAY} from '@libraries/Math.sol';
import {DelayedOracleForTest} from '@test/mocks/DelayedOracleForTest.sol';
import {Common, COLLAT, DEBT, RETH} from '@test/e2e/Common.t.sol';

uint256 constant MINUS_0_5_PERCENT_PER_HOUR = 999_998_607_628_240_588_157_433_861;
uint256 constant DEPOSIT = 0.5 ether; // $1000 worth of RETH (1 RETH = $2000)
uint256 constant MINT = 740 ether; // $740 worth of OD (135% over-collateralization)
uint256 constant USER_AMOUNT = 500 ether;
uint256 constant ELEVEN_PERCENT = 160 ether;
uint256 constant FIFTEEN_PERCENT = 218 ether;
uint256 constant TWENTY_PERCENT = 290 ether;
uint256 constant THIRTY_PERCENT = 436 ether;
uint256 constant FORTY_PERCENT = 582 ether;

contract E2ELiquidation is Common {
  using Math for uint256;

  uint256 public liquidationCRatio; // RAY
  uint256 public safetyCRatio; // RAY
  uint256 public accumulatedRate; // RAY
  uint256 public liquidationPrice; // RAY

  ISAFEEngine.SAFEEngineCollateralData public cTypeData;
  IOracleRelayer.OracleRelayerCollateralParams public oracleParams;
  ILiquidationEngine.LiquidationEngineCollateralParams public cTypeParams;

  IVault721.NFVState public aliceNFV;
  IVault721.NFVState public bobNFV;

  address public aliceProxy;
  address public bobProxy;
  uint256 public initialSystemCoinSupply;

  IERC20 public reth;

  mapping(address proxy => uint256 safeId) public vaults;

  function setUp() public virtual override {
    super.setUp();
    refreshCData(RETH);
    reth = IERC20(address(collateral[RETH]));

    cTypeParams = liquidationEngine.cParams(RETH);

    aliceProxy = userVaultSetup(RETH, alice, USER_AMOUNT, 'AliceProxy');
    aliceNFV = vault721.getNfvState(vaults[aliceProxy]);
    depositCollateralAndGenDebt(RETH, vaults[aliceProxy], DEPOSIT, MINT, aliceProxy);

    bobProxy = userVaultSetup(RETH, bob, USER_AMOUNT, 'BobProxy');
    bobNFV = vault721.getNfvState(vaults[bobProxy]);
    depositCollateralAndGenDebt(RETH, vaults[bobProxy], DEPOSIT * 3, MINT * 3, bobProxy);

    initialSystemCoinSupply = systemCoin.totalSupply();

    vm.prank(bob);
    systemCoin.approve(bobProxy, type(uint256).max);
  }

  function testAssumptions() public {
    assertEq(reth.balanceOf(alice), USER_AMOUNT - DEPOSIT);
    assertEq(reth.balanceOf(bob), USER_AMOUNT - DEPOSIT * 3);
    emitRatio(RETH, aliceNFV.safeHandler); // 135% over-collateralized
    readDelayedPrice(RETH);
    collateralDevaluation(RETH, ELEVEN_PERCENT); // 11% devaulation
    readDelayedPrice(RETH);
    emitRatio(RETH, aliceNFV.safeHandler); // 124% over-collateralized
    liquidationEngine.liquidateSAFE(RETH, aliceNFV.safeHandler);
    emit log_named_uint('Liquidation    Penalty', cTypeParams.liquidationPenalty);
  }

  /**
   * @dev initial setup
   * RETH: $2000
   * OD = $1
   * Liquidation Penalty: 5%
   * Liquidation Ratio: 125%
   * Safety Ration: 135%
   *
   * @notice scenario
   * User deposit $1000 worth of RETH (0.5 ether) and borrows $740 OD (135% ratio)
   *
   */
  function testLiquidation1() public {
    _percentLiquidation(ELEVEN_PERCENT);
  }

  function testLiquidation2() public {
    _percentLiquidation(FIFTEEN_PERCENT);
  }

  function testLiquidation3() public {
    _percentLiquidation(TWENTY_PERCENT);
  }

  function testLiquidation4() public {
    _percentLiquidation(THIRTY_PERCENT);
  }

  function testLiquidation5() public {
    _percentLiquidation(FORTY_PERCENT);
  }

  function _percentLiquidation(uint256 _percent) public {
    // read initial values
    emitRatio(RETH, aliceNFV.safeHandler);
    emitInternalAndExternalCollateralAndDebt();

    // generate amoutToRaise in case of liquidation
    uint256 _amountToRaise = _emitMathAndReturnAmountToRaise();

    // devalue cType to below the liquidation ratio
    collateralDevaluation(RETH, _percent);
    emitRatio(RETH, aliceNFV.safeHandler);

    // liquidate safe
    auctionId = liquidationEngine.liquidateSAFE(RETH, aliceNFV.safeHandler);
    emitInternalAndExternalCollateralAndDebt();

    vm.startPrank(bob);
    /// bob to buy half of auction @notice token kept in CAH
    buyCollateral(RETH, auctionId, 0, _amountToRaise / 2, bobProxy);
    emitInternalAndExternalCollateralAndDebt();

    /// bob to buy remaining half of auction @notice token returned to Alice safe
    buyCollateral(RETH, auctionId, 0, _amountToRaise / 2, bobProxy);
    emitInternalAndExternalCollateralAndDebt();
  }

  function _emitMathAndReturnAmountToRaise() public returns (uint256) {
    ILiquidationEngine.LiquidationEngineCollateralParams memory _rethParams = liquidationEngine.cParams(RETH);
    ILiquidationEngine.LiquidationEngineParams memory _liqParams = liquidationEngine.params();

    (uint256 _lc, uint256 _gd) = getSAFE(RETH, aliceNFV.safeHandler);
    uint256 _lq = _rethParams.liquidationQuantity;
    uint256 _ad =
      (_liqParams.onAuctionSystemCoinLimit - liquidationEngine.currentOnAuctionSystemCoins()).wdiv(accumulatedRate);
    uint256 _limitAdjustedDebt = Math.min(_gd, Math.min(_lq, _ad));
    // emit log_named_uint('Generated   Debt     ', _gd);
    // emit log_named_uint('Liquidation Quantity ', _lq);
    // emit log_named_uint('Adjusted    Debt     ', _ad);
    emit log_named_uint('* Limit Adjusted Debt ', _limitAdjustedDebt);

    uint256 _lcXlad = _lc * _limitAdjustedDebt / _gd;
    uint256 _collateralToSell = Math.min(_lc, _lcXlad);
    // emit log_named_uint('Locked Collateral    ', _lc);
    // emit log_named_uint('Locked C X LimAdjDebt', _lcXlad);
    emit log_named_uint('* Collateral To Sell  ', _collateralToSell);

    uint256 _amountToRaise = (_limitAdjustedDebt * accumulatedRate).wmul(_rethParams.liquidationPenalty) / 1e27;
    emit log_named_uint('* Amount     To Raise ', _amountToRaise);
    return _amountToRaise;
  }

  // HELPER FUNCTIONS
  function emitInternalAndExternalCollateralAndDebt() public {
    emit log_named_uint('CAH System   Coin  Bal', systemCoin.balanceOf(address(collateralAuctionHouse[RETH])));
    emit log_named_uint(
      'CAH Internal cType Bal', safeEngine.tokenCollateral(RETH, address(collateralAuctionHouse[RETH]))
    );
    emit log_named_uint('Ali Internal CType Bal', safeEngine.tokenCollateral(RETH, aliceNFV.safeHandler));
    (uint256 _a_c, uint256 _a_d) = getSAFE(RETH, aliceNFV.safeHandler);
    emit log_named_uint('Ali Locked   CType Bal', _a_c);
    emit log_named_uint('Ali System   Coin  Bal', systemCoin.balanceOf(alice));
    emit log_named_uint('Ali Generate Debt  Bal', _a_d);
    emit log_named_uint('----------------------', 0);
  }

  function getRatio(bytes32 _cType, uint256 _collateral, uint256 _debt) public view returns (uint256 _ratio) {
    _ratio = _collateral.wmul(oracleRelayer.cParams(_cType).oracle.read()).wdiv(_debt.wmul(accumulatedRate));
  }

  function emitRatio(bytes32 _cType, address _safe) public returns (uint256 _ratio) {
    (uint256 _collateral, uint256 _debt) = getSAFE(_cType, _safe);
    _ratio = getRatio(_cType, _collateral, _debt);
    emit log_named_uint('CType  to  Debt  Ratio', _ratio / 1e7);
  }

  function readDelayedPrice(bytes32 _cType) public returns (uint256) {
    uint256 _p = delayedOracle[_cType].read();
    emit log_named_uint('CType  Price      Read', _p);
    return _p;
  }

  function collateralDevaluation(bytes32 _cType, uint256 _devaluation) public returns (uint256) {
    uint256 _p = delayedOracle[_cType].read();
    DelayedOracleForTest(address(delayedOracle[_cType])).setPriceAndValidity(_p - _devaluation, true);
    oracleRelayer.updateCollateralPrice(_cType);
    refreshCData(_cType);
    return delayedOracle[_cType].read();
  }

  function refreshCData(bytes32 _cType) public {
    cTypeData = safeEngine.cData(_cType);
    liquidationPrice = cTypeData.liquidationPrice;
    accumulatedRate = cTypeData.accumulatedRate;

    oracleParams = oracleRelayer.cParams(_cType);
    liquidationCRatio = oracleParams.liquidationCRatio;
    safetyCRatio = oracleParams.safetyCRatio;
  }

  function userVaultSetup(
    bytes32 _cType,
    address _user,
    uint256 _amount,
    string memory _name
  ) public returns (address _proxy) {
    _proxy = deployOrFind(_user);
    mintToken(_cType, _user, _amount, _proxy);
    vm.label(_proxy, _name);
    vm.prank(_proxy);
    vaults[_proxy] = safeManager.openSAFE(_cType, _proxy);
  }
}
