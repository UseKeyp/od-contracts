// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {Common, COLLAT, DEBT, TKN} from '@testnet/e2e/Common.t.sol';
import {BaseUser} from '@testnet/scopes/BaseUser.t.sol';
import {DirectUser} from '@testnet/scopes/DirectUser.t.sol';
import {ProxyUser} from '@testnet/scopes/ProxyUser.t.sol';
import {ERC20ForTest} from '@testnet/mocks/ERC20ForTest.sol';
import {ODProxy} from '@contracts/proxies/ODProxy.sol';
import {RAY, WAD} from '@libraries/Math.sol';
import {SafeERC20} from '@openzeppelin/token/ERC20/utils/SafeERC20.sol';
import {Vault721} from '@contracts/proxies/Vault721.sol';

import {IVault721} from '@interfaces/proxies/IVault721.sol';

contract NFTSetup is Common {
  uint256 private constant MINT_AMOUNT = 1_000_000 ether;

  address public aliceProxy;
  address public bobProxy;

  ERC20ForTest public token;
  bytes32 constant WSTETH = bytes32('WSTETH');

  function setUp() public override {
    super.setUp();
    aliceProxy = deployOrFind(alice);
    bobProxy = deployOrFind(bob);
    vm.label(aliceProxy, 'AliceProxy');
    vm.label(bobProxy, 'BobProxy');

    token = ERC20ForTest(address(collateral[TKN]));
    vm.stopPrank();
  }

  function deployOrFind(address owner) public returns (address) {
    address proxy = vault721.getProxy(owner);
    if (proxy == address(0)) {
      return address(vault721.build(owner));
    } else {
      return proxy;
    }
  }

  function openSafe(bytes32 _cType, address _usr) public returns (uint256 _safeId) {
    address _proxy = deployOrFind(_usr);
    bytes memory payload = abi.encodeWithSelector(basicActions.openSAFE.selector, address(safeManager), _cType, _proxy);
    bytes memory safeData = ODProxy(_proxy).execute(address(basicActions), payload);
    _safeId = abi.decode(safeData, (uint256));
  }

  function depositCollatAndGenDebt(
    bytes32 _cType,
    uint256 _safeId,
    uint256 _collatAmount,
    uint256 _deltaWad,
    address _proxy
  ) public {
    bytes memory payload = abi.encodeWithSelector(
      basicActions.lockTokenCollateralAndGenerateDebt.selector,
      address(safeManager),
      address(collateralJoin[_cType]),
      address(coinJoin),
      _safeId,
      _collatAmount,
      _deltaWad
    );
    ODProxy(_proxy).execute(address(basicActions), payload);
  }
}

contract E2ENFTTest is NFTSetup {
  using SafeERC20 for IERC20;

  function test_openSafe() public {
    address alice = address(0x420);
    // uint256 safeId = openSafe(WSTETH, alice);
    bytes memory payload =
      abi.encodeWithSelector(basicActions.openSAFE.selector, address(safeManager), WSTETH, aliceProxy);

    vm.prank(alice);
    bytes memory safeData = ODProxy(aliceProxy).execute(address(basicActions), payload);

    // assertEq(safeId, vault721.totalSupply());

    // address safeIdOwner = Vault721(vault721).ownerOf(safeId);
    // assertEq(safeIdOwner, alice);
  }

  // function test_openSafe_lockCollateral_WSTETH() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(WSTETH, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(wsteth).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(WSTETH, vault721.totalSupply(), 0.0001 ether, 0, aliceProxy);
  //   vm.stopPrank();
  // }

  // function test_openSafe_lockCollateral_ARB() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(ARB, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(arb).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(ARB, vault721.totalSupply(), 1 ether, 0, aliceProxy);
  //   vm.stopPrank();
  // }

  // function test_openSafe_lockCollateral_generateDebt_WSTETH() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(WSTETH, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(wsteth).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(WSTETH, vault721.totalSupply(), 0.3 ether, 150 ether, aliceProxy);
  //   vm.stopPrank();
  // }

  // function test_openSafe_lockCollateral_generateDebt_ARB() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(ARB, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(arb).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(ARB, vault721.totalSupply(), 125 ether, 75 ether, aliceProxy);
  //   vm.stopPrank();
  // }

  // function test_openSafe_lockCollateral_transfer_WSTETH() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(WSTETH, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(wsteth).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(WSTETH, vault721.totalSupply(), 0.0001 ether, 0, aliceProxy);

  //   uint256 nftBalAliceBefore = Vault721(vault721).balanceOf(alice);
  //   uint256 nftBalBobBefore = Vault721(vault721).balanceOf(bob);

  //   assertEq(nftBalAliceBefore, 1);
  //   assertEq(nftBalBobBefore, 0);

  //   Vault721(vault721).transferFrom(alice, bob, vault721.totalSupply());

  //   uint256 nftBalAliceAfter = Vault721(vault721).balanceOf(alice);
  //   uint256 nftBalBobAfter = Vault721(vault721).balanceOf(bob);

  //   assertEq(nftBalAliceAfter, 0);
  //   assertEq(nftBalBobAfter, 1);
  //   vm.stopPrank();

  //   uint256[] memory _safes = safeManager.getSafes(deployOrFind(bob));
  //   assertEq(_safes.length, 1);
  //   assertEq(_safes[0], vault721.totalSupply());
  // }

  // function test_openSafe_lockCollateral_generateDebt_transfer_ARB() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(ARB, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   IERC20(arb).approve(aliceProxy, type(uint256).max);
  //   depositCollatAndGenDebt(ARB, vault721.totalSupply(), 125 ether, 75 ether, aliceProxy);

  //   uint256 nftBalAliceBefore = Vault721(vault721).balanceOf(alice);
  //   uint256 nftBalBobBefore = Vault721(vault721).balanceOf(bob);

  //   assertEq(nftBalAliceBefore, 1);
  //   assertEq(nftBalBobBefore, 0);

  //   Vault721(vault721).transferFrom(alice, bob, vault721.totalSupply());

  //   uint256 nftBalAliceAfter = Vault721(vault721).balanceOf(alice);
  //   uint256 nftBalBobAfter = Vault721(vault721).balanceOf(bob);

  //   assertEq(nftBalAliceAfter, 0);
  //   assertEq(nftBalBobAfter, 1);
  //   vm.stopPrank();

  //   uint256[] memory _safes = safeManager.getSafes(deployOrFind(bob));
  //   assertEq(_safes.length, 1);
  //   assertEq(_safes[0], vault721.totalSupply());
  // }

  // todo: uncomment after next Sepolia deployment
  // function test_openSafe_transferToProxyFail() public {
  //   vm.startPrank(alice);

  //   uint256 safeId = openSafe(ARB, alice);
  //   assertEq(safeId, vault721.totalSupply());

  //   vm.expectRevert(Vault721.NotWallet.selector);
  //   Vault721(vault721).transferFrom(alice, bobProxy, safeId);
  //   vm.stopPrank();
  // }
}
