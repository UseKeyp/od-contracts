// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';

// --- Base Contracts ---
import {ISystemCoin} from '@interfaces/tokens/ISystemCoin.sol';
import {IProtocolToken} from '@interfaces/tokens/IProtocolToken.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {ITaxCollector} from '@interfaces/ITaxCollector.sol';
import {IAccountingEngine} from '@interfaces/IAccountingEngine.sol';
import {ILiquidationEngine} from '@interfaces/ILiquidationEngine.sol';
import {ISurplusAuctionHouse} from '@interfaces/ISurplusAuctionHouse.sol';
import {IDebtAuctionHouse} from '@interfaces/IDebtAuctionHouse.sol';
import {ICollateralAuctionHouse} from '@interfaces/ICollateralAuctionHouse.sol';
import {IStabilityFeeTreasury} from '@interfaces/IStabilityFeeTreasury.sol';
import {IPIDController} from '@interfaces/IPIDController.sol';
import {IPIDRateSetter} from '@interfaces/IPIDRateSetter.sol';

// --- Settlement ---
import {IGlobalSettlement} from '@interfaces/settlement/IGlobalSettlement.sol';
import {IPostSettlementSurplusAuctionHouse} from '@interfaces/settlement/IPostSettlementSurplusAuctionHouse.sol';
import {ISettlementSurplusAuctioneer} from '@interfaces/settlement/ISettlementSurplusAuctioneer.sol';

// --- Oracles ---
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';

// --- Token adapters ---
import {ICoinJoin} from '@interfaces/utils/ICoinJoin.sol';
import {ICollateralJoin} from '@interfaces/utils/ICollateralJoin.sol';

// --- Factories ---
import {ICollateralJoinFactory} from '@interfaces/factories/ICollateralJoinFactory.sol';
import {ICollateralAuctionHouseFactory} from '@interfaces/factories/ICollateralAuctionHouseFactory.sol';
import {IChainlinkRelayerFactory} from '@interfaces/factories/IChainlinkRelayerFactory.sol';
import {IDenominatedOracleFactory} from '@interfaces/factories/IDenominatedOracleFactory.sol';
import {IDelayedOracleFactory} from '@interfaces/factories/IDelayedOracleFactory.sol';

// --- Jobs ---
import {IAccountingJob} from '@interfaces/jobs/IAccountingJob.sol';
import {ILiquidationJob} from '@interfaces/jobs/ILiquidationJob.sol';
import {IOracleJob} from '@interfaces/jobs/IOracleJob.sol';

// --- Proxy Contracts ---
import {IBasicActions} from '@interfaces/proxies/actions/IBasicActions.sol';
import {IDebtBidActions} from '@interfaces/proxies/actions/IDebtBidActions.sol';
import {ISurplusBidActions} from '@interfaces/proxies/actions/ISurplusBidActions.sol';
import {ICollateralBidActions} from '@interfaces/proxies/actions/ICollateralBidActions.sol';
import {PostSettlementSurplusBidActions} from '@contracts/proxies/actions/PostSettlementSurplusBidActions.sol';
import {IGlobalSettlementActions} from '@interfaces/proxies/actions/IGlobalSettlementActions.sol';
import {IRewardedActions} from '@interfaces/proxies/actions/IRewardedActions.sol';
import {IODSafeManager} from '@interfaces/proxies/IODSafeManager.sol';
import {IVault721} from '@interfaces/proxies/IVault721.sol';
import {NFTRenderer} from '@contracts/proxies/NFTRenderer.sol';

// --- Governance Contracts ---
import {TimelockController} from '@openzeppelin/governance/TimelockController.sol';
import {ODGovernor} from '@contracts/gov/ODGovernor.sol';

library OpenDollarV1Arbitrum {
  /// @dev Open Dollar Coin
  ISystemCoin internal constant SYSTEM_COIN = ISystemCoin(0x221A0f68770658C15B525d0F89F5da2baAB5f321);

  /// @dev Open Dollar Governance Token
  IProtocolToken internal constant PROTOCOL_TOKEN = IProtocolToken(0x000D636bD52BFc1B3a699165Ef5aa340BEA8939c);

  /// @dev ERC721 Non Fungible Vault
  IVault721 internal constant VAULT721 = IVault721(0x0005AFE00fF7E7FF83667bFe4F2996720BAf0B36);

  /// @dev Timelock Controller for OD Governor
  TimelockController internal constant OD_TIMELOCK_CONTROLLER =
    TimelockController(payable(0x7A528eA3E06D85ED1C22219471Cf0b1851943903));

  /// @dev OD Governor for Open-Dollar DAO
  ODGovernor internal constant OD_GOVERNOR = ODGovernor(payable(0xf704735CE81165261156b41D33AB18a08803B86F));

  /// @dev Deploy Delayed Oracles
  IDelayedOracleFactory internal constant DELAYED_ORACLE_FACTORY =
    IDelayedOracleFactory(0x9Dd63fA54dEfd8820BCAb3e3cC39aeEc1aE88098);

  /// @dev ARB Delayed Oracle
  IDelayedOracle internal constant DELAYED_ORACLE_CHILD_ARB = IDelayedOracle(0xa4e0410E7eb9a02aa9C0505F629d01890c816A77);

  /// @dev WSTETH Delayed Oracle
  IDelayedOracle internal constant DELAYED_ORACLE_CHILD_WSTETH =
    IDelayedOracle(0x026d81728a24c0F20A83c9263A455922c70b84aC);

  /// @dev RETH Delayed Oracle
  IDelayedOracle internal constant DELAYED_ORACLE_CHILD_RETH =
    IDelayedOracle(0x9420eFb9808b0ed432Ad5AD41C302bc908FE344f);

  /// @dev Safe Engine
  ISAFEEngine internal constant SAFE_ENGINE = ISAFEEngine(0xEff45E8e2353893BD0558bD5892A42786E9142F1);

  /// @dev Oracle Relayer
  IOracleRelayer internal constant ORACLE_RELAYER = IOracleRelayer(0x7404fc1F3796748FAE17011b57Fad9713185c1d6);

  /// @dev SAH
  ISurplusAuctionHouse internal constant SURPLUS_AUCTION_HOUSE =
    ISurplusAuctionHouse(0xA18aFB1953648ec7465d536287a015C237927369);

  /// @dev DAH
  IDebtAuctionHouse internal constant DEBT_AUCTION_HOUSE = IDebtAuctionHouse(0x5A021f2063bc2D26fd24a632e29587Afe14D30e5);

  /// @dev Accounting Engine
  IAccountingEngine internal constant ACCOUNTING_ENGINE = IAccountingEngine(0x92Bbc105430F96ddB09300A3b94cf77E3538d92c);

  /// @dev Liquidation Engine
  ILiquidationEngine internal constant LIQUIDATION_ENGINE =
    ILiquidationEngine(0x17e546dDCE2EA8A74Bd667269457A2e80b309965);

  /// @dev CAH Factory
  ICollateralAuctionHouseFactory internal constant COLLATERAL_AUCTION_HOUSE_FACTORY =
    ICollateralAuctionHouseFactory(0x5dc1E86361faC018f24Ae0D1E5eB01D70AB32A82);

  /// @dev System Coin (OD) Join
  ICoinJoin internal constant COIN_JOIN = ICoinJoin(0xeE4393C6165a416c83756198A56395F48bbf480f);

  /// @dev Collateral Join Factory
  ICollateralJoinFactory internal constant COLLATERAL_JOIN_FACTORY =
    ICollateralJoinFactory(0xa83c0f1e9eD8E383919Dde0fC90744ae370EB7B3);

  /// @dev Tax Collector
  ITaxCollector internal constant TAX_COLLECTOR = ITaxCollector(0xc93F938A95488a03b976A15B20fAcFD52D087fB2);

  /// @dev Stability Fee Treasury
  IStabilityFeeTreasury internal constant STABILITY_FEE_TREASURY =
    IStabilityFeeTreasury(0x9C86C719Aa29D426C50Ee3BAEd40008D292b02CF);

  /// @dev Global Settlement for Global Shutdown Event
  IGlobalSettlement internal constant GLOBAL_SETTLEMENT = IGlobalSettlement(0x1c6B7ab018be82ed6b5c63aE82D9f07bb7B231A2);

  /// @dev Post-Settlement SAH for Global Shutdown Event
  IPostSettlementSurplusAuctionHouse internal constant POSTSETTLEMENT_SURPLUS_AUCTION_HOUSE =
    IPostSettlementSurplusAuctionHouse(0x9b9ae60c5475c0735125c3Fb42345AAB780a7a2c);

  /// @dev Settlement Actioneer
  ISettlementSurplusAuctioneer internal constant SETTLEMENT_SURPLUS_AUCTIONEER =
    ISettlementSurplusAuctioneer(0x6c70B191Fc602Bd3756F0aB3684662BBfD8599A6);

  /// @dev PID Controller
  IPIDController internal constant PID_CONTROLLER = IPIDController(0x51f0434645Aa8a98cFa9f0fE7b373297a95Fe92C);

  /// @dev PID Rate Setter
  IPIDRateSetter internal constant PID_RATE_SETTER = IPIDRateSetter(0xBbb7cC351e323f069602B28B3087b5A50Eb9C654);

  /// @dev Accounting Job
  IAccountingJob internal constant ACCOUNTING_JOB = IAccountingJob(0x724f970b507F120f81130cE3924d738Db08d69f2);

  /// @dev Liquidation Job
  ILiquidationJob internal constant LIQUIDATION_JOB = ILiquidationJob(0x667F9a20d887Ff5943CCf6B35944332aDAE7E2ED);

  /// @dev Oracle Job
  IOracleJob internal constant ORACLE_JOB = IOracleJob(0xFaD87e9c629c5c8D84eDB3A134fB998AC80995Ee);

  /// @dev Collateral Join for ARB
  ICollateralJoin internal constant COLLATERAL_JOIN_CHILD_ARB =
    ICollateralJoin(0x526Afa46F46Fd80BAa7A6CB62169e59309854611);

  /// @dev CAH for ARB
  ICollateralAuctionHouse internal constant CAH_CHILD_ARB =
    ICollateralAuctionHouse(0x42757A0f17CbE17014f7f914c4146AC7D7f44bB4);

  /// @dev Collateral Join for WSTETH
  ICollateralJoin internal constant COLLATERAL_JOIN_CHILD_WSTETH =
    ICollateralJoin(0xae7Df58bB63b2Db798f85AB7BCACE340d55f6f39);

  /// @dev CAH for WSTETH
  ICollateralAuctionHouse internal constant CAH_CHILD_WSTETH =
    ICollateralAuctionHouse(0x0365dFC776851e970bd6269a2862eFc9a6265273);

  /// @dev Collateral Join for RETH
  ICollateralJoin internal constant COLLATERAL_JOIN_CHILD_RETH =
    ICollateralJoin(0xC215F3509AFbB303Bf4a20CBFAA5382fad9bEA1D);

  /// @dev CAH for RETH
  ICollateralAuctionHouse internal constant CAH_CHILD_RETH =
    ICollateralAuctionHouse(0x51a423B43101B219a9ECdEC67525896d856186Ec);

  /// @dev Safe Mananger to interact with Safe Engine
  IODSafeManager internal constant SAFE_MANANGER = IODSafeManager(0x8646CBd915eAAD1a4E2Ba5e2b67Acec4957d5f1a);

  /// @dev Renderer of NFV SVG
  NFTRenderer internal constant NFT_RENDERER = NFTRenderer(0xFDB6935CF3A6441f83adF60CF5C9bf89A4fd7681);

  /// @dev Basic Actions (inherit Common Actions)
  IBasicActions internal constant BASIC_ACTIONS = IBasicActions(0x688CFd8024ba60030fE4D669fd45D914A82933db);

  /// @dev Debt Bid Actions
  IDebtBidActions internal constant DEBT_BID_ACTIONS = IDebtBidActions(0x490CEDC57E1D2409F111C6a6Db75AC6A7Fc45E4a);

  /// @dev Surplus Bid Actions
  ISurplusBidActions internal constant SURPLUS_BID_ACTIONS =
    ISurplusBidActions(0x8F43FdD337C0A84f0d00C70F3c4E6A4E52A84C7E);

  /// @dev Collateral Bid Actions
  ICollateralBidActions internal constant COLLATERAL_BID_ACTIONS =
    ICollateralBidActions(0xb60772EDb81a143D98c4aB0bD1C671a5E5184179);

  /// @dev Post-Settlement Bid Actions for Global Shutdown Event
  PostSettlementSurplusBidActions internal constant POSTSETTLEMENT_SURPLUS_BID_ACTIONS =
    PostSettlementSurplusBidActions(0x2B7F191E4FdCf4E354f344349302BC3E98780044);

  /// @dev Global Settlement Actions for Global Shutdown Event
  IGlobalSettlementActions internal constant GLOBAL_SETTLEMENT_ACTIONS =
    IGlobalSettlementActions(0xBB935d412DFab5200D01B1fcaF2aa14Af5b5b2ED);

  /// @dev Rewarded Actions
  IRewardedActions internal constant REWARDED_ACTIONS = IRewardedActions(0xD51fD52C5BCC150491d1e629094a3A56B7194096);

  /// @dev Deploy Chainlink Oracles
  IChainlinkRelayerFactory internal constant CHAINLINK_RELAYER_FACTORY =
    IChainlinkRelayerFactory(0x06C32500489C28Bd57c551afd8311Fef20bFaBB5);

  /// @dev Deploy Denominated Oracles
  IDenominatedOracleFactory internal constant DENOMINATED_ORACLE_FACTORY =
    IDenominatedOracleFactory(0xBF760b23d2ef3615cec549F22b95a34DB0F8f5CD);

  /// @dev Deploy Camelot Oracles (interface in od-relayer repo)
  address internal constant CAMELOT_RELAYER_FACTORY = 0x36645830479170265A154Acb726780fdaE41A28F;

  /// @dev Collateral IERC20Metadata Tokens
  IERC20Metadata internal constant WETH = IERC20Metadata(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IERC20Metadata internal constant WSTETH = IERC20Metadata(0x5979D7b546E38E414F7E9822514be443A4800529);
  IERC20Metadata internal constant RETH = IERC20Metadata(0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8);
  IERC20Metadata internal constant ARB = IERC20Metadata(0x912CE59144191C1204E64559FE8253a0e49E6548);
}
