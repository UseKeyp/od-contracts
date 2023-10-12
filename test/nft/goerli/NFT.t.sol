// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {GoerliFork} from '@test/nft/goerli/GoerliFork.t.sol';
import {GoerliParams, WSTETH, ARB, CBETH, RETH, MAGIC} from '@script/GoerliParams.s.sol';
import {GOERLI_WETH, GOERLI_GOV_TOKEN} from '@script/Registry.s.sol';
import {IERC20} from '@openzeppelin/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/token/ERC20/utils/SafeERC20.sol';
import {Vault721} from '@contracts/proxies/Vault721.sol';

// forge t --fork-url $URL --match-contract NFTGoerli -vvv

contract NFTGoerli is GoerliFork {
  using SafeERC20 for IERC20;

  /**
   * @dev tests are grouped into 1 function to avoid being run general test
   * change `X_all` to `test_all` to run tests in this contract
   */

  function X_all() public {
    t_openSafe_WETH();
    t_openSafe_ARB();
    t_openSafe_lockCollateral_WETH();
    t_openSafe_lockCollateral_ARB();
    t_openSafe_lockCollateral_generateDebt_WETH();
    t_openSafe_lockCollateral_generateDebt_ARB();
    t_openSafe_lockCollateral_transfer_WETH();
    t_openSafe_lockCollateral_generateDebt_transfer_ARB();
  }

  function t_openSafe_WETH() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(WSTETH, aliceProxy);
    assertEq(safeId, currSafeId);

    address ownerOfToken = Vault721(vault721).ownerOf(safeId);
    assertEq(ownerOfToken, alice);
    vm.stopPrank();
  }

  function t_openSafe_ARB() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(ARB, aliceProxy);
    assertEq(safeId, currSafeId);

    address ownerOfToken = Vault721(vault721).ownerOf(safeId);
    assertEq(ownerOfToken, alice);
    vm.stopPrank();
  }

  function t_openSafe_lockCollateral_WETH() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(WSTETH, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_WETH).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(WSTETH, currSafeId, 0.0001 ether, 0, aliceProxy);
    vm.stopPrank();
  }

  function t_openSafe_lockCollateral_ARB() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(ARB, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_GOV_TOKEN).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(ARB, currSafeId, 1 ether, 0, aliceProxy);
    vm.stopPrank();
  }

  function t_openSafe_lockCollateral_generateDebt_WETH() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(WSTETH, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_WETH).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(WSTETH, currSafeId, 0.3 ether, 150 ether, aliceProxy);
    vm.stopPrank();
  }

  function t_openSafe_lockCollateral_generateDebt_ARB() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(ARB, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_GOV_TOKEN).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(ARB, currSafeId, 125 ether, 75 ether, aliceProxy);
    vm.stopPrank();
  }

  function t_openSafe_lockCollateral_transfer_WETH() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(WSTETH, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_WETH).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(WSTETH, currSafeId, 0.0001 ether, 0, aliceProxy);

    uint256 nftBalAliceBefore = Vault721(vault721).balanceOf(alice);
    assertEq(nftBalAliceBefore, 2);
    Vault721(vault721).transferFrom(alice, bob, currSafeId);

    uint256 nftBalAlice = Vault721(vault721).balanceOf(alice);
    uint256 nftBalBob = Vault721(vault721).balanceOf(bob);

    assertEq(nftBalAlice, 1);
    assertEq(nftBalBob, 1);
    vm.stopPrank();

    uint256[] memory _safes = safeManager.getSafes(deployOrFind(bob));
    assertEq(_safes.length, 1);
    assertEq(_safes[0], currSafeId);
  }

  function t_openSafe_lockCollateral_generateDebt_transfer_ARB() public {
    vm.startPrank(alice);

    uint256 safeId = openSafe(ARB, aliceProxy);
    assertEq(safeId, currSafeId);

    IERC20(GOERLI_GOV_TOKEN).approve(aliceProxy, type(uint256).max);
    depositCollatAndGenDebt(ARB, currSafeId, 125 ether, 75 ether, aliceProxy);

    uint256 nftBalAliceBefore = Vault721(vault721).balanceOf(alice);
    assertEq(nftBalAliceBefore, 2);
    Vault721(vault721).transferFrom(alice, bob, currSafeId);

    uint256 nftBalAlice = Vault721(vault721).balanceOf(alice);
    uint256 nftBalBob = Vault721(vault721).balanceOf(bob);

    assertEq(nftBalAlice, 1);
    assertEq(nftBalBob, 1);
    vm.stopPrank();

    uint256[] memory _safes = safeManager.getSafes(deployOrFind(bob));
    assertEq(_safes.length, 1);
    assertEq(_safes[0], currSafeId);
  }
}
