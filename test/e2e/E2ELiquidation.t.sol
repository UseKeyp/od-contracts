// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {ODProxy} from '@contracts/proxies/ODProxy.sol';
import {IVault721} from '@interfaces/proxies/IVault721.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';
import {Math, RAY} from '@libraries/Math.sol';
import {DelayedOracleForTest} from '@test/mocks/DelayedOracleForTest.sol';
import {Common, COLLAT, DEBT, RETH} from '@test/e2e/Common.t.sol';

uint256 constant MINUS_0_5_PERCENT_PER_HOUR = 999_998_607_628_240_588_157_433_861;
uint256 constant DEPOSIT = 0.5 ether; // $1000 worth of RETH (1 RETH = $2000)
uint256 constant MINT = 740 ether; // $740 worth of OD (135% over-collateralization)
uint256 constant USER_AMOUNT = 500 ether;

contract E2ELiquidation is Common {
  using Math for uint256;

  uint256 public liquidationCRatio; // RAY
  uint256 public safetyCRatio; // RAY
  uint256 public accumulatedRate; // RAY
  uint256 public liquidationPrice; // RAY

  ISAFEEngine.SAFEEngineCollateralData public cTypeData;
  IOracleRelayer.OracleRelayerCollateralParams public oracleParams;

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

    aliceProxy = userVaultSetup(RETH, alice, USER_AMOUNT, 'AliceProxy');
    aliceNFV = vault721.getNfvState(vaults[aliceProxy]);
    depositCollateralAndGenDebt(RETH, vaults[aliceProxy], DEPOSIT, MINT, aliceProxy);

    bobProxy = userVaultSetup(RETH, bob, USER_AMOUNT, 'BobProxy');
    bobNFV = vault721.getNfvState(vaults[bobProxy]);
    depositCollateralAndGenDebt(RETH, vaults[bobProxy], DEPOSIT * 3, MINT * 3, bobProxy);

    initialSystemCoinSupply = systemCoin.totalSupply();

    vm.prank(bob);
    systemCoin.approve(bobProxy, USER_AMOUNT);
  }

  function testAssumptions() public {
    assertEq(reth.balanceOf(alice), USER_AMOUNT - DEPOSIT);
    assertEq(reth.balanceOf(bob), USER_AMOUNT - DEPOSIT * 3);
    assertEq(systemCoin.totalSupply(), 1480 ether);
    readDelayedPrice(RETH);
    collateralDevaluation(RETH, 200 ether); // 10% devaulation; 135% => 125% over-collateralization
    readDelayedPrice(RETH);
    emitRatio(RETH, aliceNFV.safeHandler);
    liquidationEngine.liquidateSAFE(RETH, aliceNFV.safeHandler);
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
  function testLiquidation() public {}

  // HELPER FUNCTIONS
  function readDelayedPrice(bytes32 _cType) public returns (uint256) {
    uint256 _p = delayedOracle[_cType].read();
    emit log_named_uint('CType  Price   Read', _p);
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

  function mintToken(bytes32 _cType, address _account, uint256 _amount, address _okAccount) public {
    vm.startPrank(_account);
    deal(address(collateral[_cType]), _account, _amount);
    if (_okAccount != address(0)) {
      IERC20(address(collateral[_cType])).approve(_okAccount, _amount);
    }
    vm.stopPrank();
  }

  function deployOrFind(address _owner) public returns (address) {
    address proxy = vault721.getProxy(_owner);
    if (proxy == address(0)) {
      return address(vault721.build(_owner));
    } else {
      return proxy;
    }
  }

  function depositCollateralAndGenDebt(
    bytes32 _cType,
    uint256 _safeId,
    uint256 _collatAmount,
    uint256 _deltaWad,
    address _proxy
  ) public {
    vm.startPrank(ODProxy(_proxy).OWNER());
    bytes memory _payload = abi.encodeWithSelector(
      basicActions.lockTokenCollateralAndGenerateDebt.selector,
      address(safeManager),
      address(collateralJoin[_cType]),
      address(coinJoin),
      _safeId,
      _collatAmount,
      _deltaWad
    );
    ODProxy(_proxy).execute(address(basicActions), _payload);
    vm.stopPrank();
  }

  function buyCollateral(
    bytes32 _cType,
    uint256 _auctionId,
    uint256 _minCollateral,
    uint256 _bid,
    address _proxy
  ) public {
    vm.startPrank(ODProxy(_proxy).OWNER());
    bytes memory _payload = abi.encodeWithSelector(
      collateralBidActions.buyCollateral.selector,
      address(coinJoin),
      address(collateralJoin[_cType]),
      address(collateralAuctionHouse[_cType]),
      _auctionId,
      _minCollateral,
      _bid
    );
    ODProxy(_proxy).execute(address(collateralBidActions), _payload);
    vm.stopPrank();
  }

  function getSAFE(bytes32 _cType, address _safe) public view returns (uint256 _collateral, uint256 _debt) {
    ISAFEEngine.SAFE memory _safeData = safeEngine.safes(_cType, _safe);
    _collateral = _safeData.lockedCollateral;
    _debt = _safeData.generatedDebt;
  }

  function getRatio(bytes32 _cType, uint256 _collateral, uint256 _debt) public view returns (uint256 _ratio) {
    _ratio = _collateral.wmul(oracleRelayer.cParams(_cType).oracle.read()).wdiv(_debt.wmul(accumulatedRate));
  }

  function emitRatio(bytes32 _cType, address _safe) public returns (uint256 _ratio) {
    (uint256 _collateral, uint256 _debt) = getSAFE(_cType, _safe);
    _ratio = getRatio(_cType, _collateral, _debt);
    emit log_named_uint('CType to Debt Ratio', _ratio);
  }
}
