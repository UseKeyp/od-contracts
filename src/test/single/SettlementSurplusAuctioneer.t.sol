pragma solidity 0.8.19;

import 'ds-test/test.sol';
import {DSToken as DSDelegateToken} from '../../contracts/for-test/DSToken.sol';

import {PostSettlementSurplusAuctionHouse} from '../../contracts/SurplusAuctionHouse.sol';
import '../../contracts/SettlementSurplusAuctioneer.sol';
import {TestSAFEEngine as SAFEEngine} from './SAFEEngine.t.sol';
import {CoinJoin} from '../../contracts/utils/CoinJoin.sol';
import {Coin} from '../../contracts/utils/Coin.sol';

abstract contract Hevm {
  function warp(uint256) public virtual;
}

contract AccountingEngine {
  uint256 public contractEnabled = 1;
  uint256 public surplusAuctionDelay;
  uint256 public surplusAuctionAmountToSell;

  address public safeEngine;

  function modifyParameters(bytes32 parameter, uint256 data) external {
    if (parameter == 'surplusAuctionDelay') surplusAuctionDelay = data;
    else if (parameter == 'surplusAuctionAmountToSell') surplusAuctionAmountToSell = data;
    else revert('AccountingEngine/modify-unrecognized-param');
  }

  function modifyParameters(bytes32 parameter, address data) external {
    if (parameter == 'safeEngine') {
      safeEngine = data;
    } else {
      revert('AccountingEngine/modify-unrecognized-param');
    }
  }

  function toggle() external {
    contractEnabled = (contractEnabled == 1) ? 0 : 1;
  }
}

contract SingleSettlementSurplusAuctioneerTest is DSTest {
  Hevm hevm;

  SettlementSurplusAuctioneer surplusAuctioneer;
  PostSettlementSurplusAuctionHouse surplusAuctionHouse;
  AccountingEngine accountingEngine;
  SAFEEngine safeEngine;
  DSDelegateToken protocolToken;

  function setUp() public {
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    hevm.warp(604_411_200);

    safeEngine = new SAFEEngine();
    accountingEngine = new AccountingEngine();
    protocolToken = new DSDelegateToken('', '');

    accountingEngine.modifyParameters('safeEngine', address(safeEngine));
    accountingEngine.modifyParameters('surplusAuctionAmountToSell', 100 ether * 10 ** 9);
    accountingEngine.modifyParameters('surplusAuctionDelay', 3600);

    surplusAuctionHouse = new PostSettlementSurplusAuctionHouse(address(safeEngine), address(protocolToken));
    surplusAuctioneer = new SettlementSurplusAuctioneer(address(accountingEngine), address(surplusAuctionHouse));
    surplusAuctionHouse.addAuthorization(address(surplusAuctioneer));

    safeEngine.approveSAFEModification(address(surplusAuctionHouse));
    protocolToken.approve(address(surplusAuctionHouse));

    safeEngine.createUnbackedDebt(address(this), address(this), 1000 ether);

    protocolToken.mint(1000 ether);
    protocolToken.setOwner(address(surplusAuctionHouse));
  }

  function test_modify_parameters() public {
    surplusAuctioneer.modifyParameters('accountingEngine', address(0x1234));
    surplusAuctioneer.modifyParameters('surplusAuctionHouse', address(0x1234));

    assertEq(safeEngine.safeRights(address(surplusAuctioneer), address(surplusAuctionHouse)), 0);
    assertEq(safeEngine.safeRights(address(surplusAuctioneer), address(0x1234)), 1);

    assertTrue(address(surplusAuctioneer.accountingEngine()) == address(0x1234));
    assertTrue(address(surplusAuctioneer.surplusAuctionHouse()) == address(0x1234));
  }

  function testFail_auction_when_accounting_still_enabled() public {
    safeEngine.mint(address(surplusAuctioneer), 100 ether * 10 ** 9);
    surplusAuctioneer.auctionSurplus();
  }

  function testFail_auction_without_waiting_for_delay() public {
    accountingEngine.toggle();
    safeEngine.mint(address(surplusAuctioneer), 500 ether * 10 ** 9);
    surplusAuctioneer.auctionSurplus();
    surplusAuctioneer.auctionSurplus();
  }

  function test_auction_surplus() public {
    accountingEngine.toggle();
    safeEngine.mint(address(surplusAuctioneer), 500 ether * 10 ** 9);
    uint256 id = surplusAuctioneer.auctionSurplus();
    assertEq(id, 1);
    (uint256 bidAmount, uint256 amountToSell, address highBidder,,) = surplusAuctionHouse.bids(id);
    assertEq(bidAmount, 0);
    assertEq(amountToSell, 100 ether * 10 ** 9);
    assertEq(highBidder, address(surplusAuctioneer));
  }

  function test_trigger_second_auction_after_delay() public {
    accountingEngine.toggle();
    safeEngine.mint(address(surplusAuctioneer), 500 ether * 10 ** 9);
    surplusAuctioneer.auctionSurplus();
    hevm.warp(block.timestamp + accountingEngine.surplusAuctionDelay());
    surplusAuctioneer.auctionSurplus();
  }

  function test_nothing_to_auction() public {
    accountingEngine.toggle();
    safeEngine.mint(address(surplusAuctioneer), 1);
    surplusAuctioneer.auctionSurplus();
    hevm.warp(block.timestamp + accountingEngine.surplusAuctionDelay());
    uint256 id = surplusAuctioneer.auctionSurplus();
    assertEq(id, 0);
    (uint256 bidAmount, uint256 amountToSell, address highBidder,,) = surplusAuctionHouse.bids(2);
    assertEq(bidAmount, 0);
    assertEq(amountToSell, 0);
    assertEq(highBidder, address(0));
  }
}
