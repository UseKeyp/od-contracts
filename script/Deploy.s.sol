// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import 'forge-std/console2.sol';

import '@script/Contracts.s.sol';
import '@script/Registry.s.sol';
import '@script/Params.s.sol';

import {FixedPointMathLib} from '@isolmate/utils/FixedPointMathLib.sol';
import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';
import {Script} from 'forge-std/Script.sol';
import {Common} from '@script/Common.s.sol';
import {GoerliParams} from '@script/GoerliParams.s.sol';
import {MainnetParams} from '@script/MainnetParams.s.sol';
import {IAlgebraPool} from '@cryptoalgebra-core/interfaces/IAlgebraPool.sol';

abstract contract Deploy is Common, Script {
  function setupEnvironment() public virtual {}
  function setupPostEnvironment() public virtual {}
  function mintAirdrop() public virtual {}
  function deployGovernor() public virtual {}

  function run() public {
    deployer = vm.addr(_deployerPk);
    vm.startBroadcast(deployer);

    // set governor to deployer during deployment
    governor = deployer;
    delegate = address(0);

    //print the commit hash
    string[] memory inputs = new string[](3);
    inputs[0] = 'git';
    inputs[1] = 'rev-parse';
    inputs[2] = 'HEAD';

    bytes memory res = vm.ffi(inputs);

    // Deploy oracle factories used to setup the environment
    deployOracleFactories();

    // Environment may be different for each network
    setupEnvironment();

    // Common deployment routine for all networks
    deployContracts();
    deployTaxModule();
    _setupContracts();

    deployGlobalSettlement();
    _setupGlobalSettlement();

    // PID Controller contracts
    deployPIDController();
    _setupPIDController();

    // Rewarded Actions contracts
    deployJobContracts();
    _setupJobContracts();

    // Deploy collateral contracts
    for (uint256 _i; _i < collateralTypes.length; _i++) {
      bytes32 _cType = collateralTypes[_i];

      if (_cType == ETH_A) deployEthCollateralContracts();
      else deployCollateralContracts(_cType);
      _setupCollateral(_cType);
    }

    // Mint initial ODG airdrop
    mintAirdrop();

    // Deploy DAO Governor
    deployGovernor();

    // Deploy contracts related to the SafeManager usecase
    deployProxyContracts();

    // Deploy and setup contracts that rely on deployed environment
    setupPostEnvironment();

    // set governor to DAO
    governor = vault721.governor();
    delegate = address(0);

    if (delegate == address(0)) {
      _revokeAllTo(governor);
    } else if (delegate == deployer) {
      _delegateAllTo(governor);
    } else {
      _delegateAllTo(delegate);
      _revokeAllTo(governor);
    }

    vm.stopBroadcast();
  }
}

contract DeployMainnet is MainnetParams, Deploy {
  function setUp() public virtual {
    _deployerPk = uint256(vm.envBytes32('MAINNET_DEPLOYER_PK'));
    chainId = 42_161;
  }

  function mintAirdrop() public virtual override {
    require(DAO_SAFE != address(0), 'DAO zeroAddress');
    protocolToken.mint(DAO_SAFE, AIRDROP_AMOUNT);
  }

  function deployGovernor() public virtual override {
    require(DAO_SAFE != address(0), 'DAO zeroAddress');
    address[] memory members = new address[](1);
    members[0] = DAO_SAFE;

    timelockController = new TimelockController(MIN_DELAY, members, members, TIMELOCK_ADMIN);
    odGovernor = new ODGovernor(address(protocolToken), timelockController);
  }

  // Setup oracle feeds
  function setupEnvironment() public virtual override updateParams {
    // to USD
    IBaseOracle _ethUSDPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_ETH_USD_FEED, ORACLE_INTERVAL_PROD);

    IBaseOracle _arbUSDPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_ARB_USD_FEED, ORACLE_INTERVAL_PROD);

    IBaseOracle _magicUSDPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_MAGIC_USD_FEED, ORACLE_INTERVAL_PROD);

    // to ETH
    IBaseOracle _wstethETHPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_WSTETH_ETH_FEED, ORACLE_INTERVAL_PROD);

    IBaseOracle _cbethETHPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_CBETH_ETH_FEED, ORACLE_INTERVAL_PROD);

    IBaseOracle _rethETHPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(CHAINLINK_RETH_ETH_FEED, ORACLE_INTERVAL_PROD);

    // denominations
    IBaseOracle _wstethUSDPriceFeed =
      denominatedOracleFactory.deployDenominatedOracle(_wstethETHPriceFeed, _ethUSDPriceFeed, false);

    IBaseOracle _cbethUSDPriceFeed =
      denominatedOracleFactory.deployDenominatedOracle(_cbethETHPriceFeed, _ethUSDPriceFeed, false);

    IBaseOracle _rethUSDPriceFeed =
      denominatedOracleFactory.deployDenominatedOracle(_rethETHPriceFeed, _ethUSDPriceFeed, false);

    systemCoinOracle = new OracleForTest(OD_INITIAL_PRICE); // 1 OD = 1 USD

    delayedOracle[ARB] = delayedOracleFactory.deployDelayedOracle(_arbUSDPriceFeed, ORACLE_INTERVAL_PROD);
    delayedOracle[WSTETH] = delayedOracleFactory.deployDelayedOracle(_wstethUSDPriceFeed, ORACLE_INTERVAL_PROD);
    delayedOracle[CBETH] = delayedOracleFactory.deployDelayedOracle(_cbethUSDPriceFeed, ORACLE_INTERVAL_PROD);
    delayedOracle[RETH] = delayedOracleFactory.deployDelayedOracle(_rethUSDPriceFeed, ORACLE_INTERVAL_PROD);
    delayedOracle[MAGIC] = delayedOracleFactory.deployDelayedOracle(_magicUSDPriceFeed, ORACLE_INTERVAL_PROD);

    collateral[ARB] = IERC20Metadata(ARBITRUM_ARB);
    collateral[WSTETH] = IERC20Metadata(ARBITRUM_WSTETH);
    collateral[CBETH] = IERC20Metadata(ARBITRUM_CBETH);
    collateral[RETH] = IERC20Metadata(ARBITRUM_RETH);
    collateral[MAGIC] = IERC20Metadata(ARBITRUM_MAGIC);

    collateralTypes.push(ARB);
    collateralTypes.push(WSTETH);
    collateralTypes.push(CBETH);
    collateralTypes.push(RETH);
    collateralTypes.push(MAGIC);
  }

  function setupPostEnvironment() public virtual override updateParams {}
}

abstract contract DeployTestnet is GoerliParams, Deploy {
  function mintAirdrop() public virtual override {
    protocolToken.mint(H, AIRDROP_AMOUNT / 3);
    protocolToken.mint(J, AIRDROP_AMOUNT / 3);
    protocolToken.mint(P, AIRDROP_AMOUNT / 3);
  }

  function deployGovernor() public virtual override {
    address[] memory members = new address[](3);
    members[0] = H;
    members[1] = J;
    members[2] = P;

    timelockController = new TimelockController(MIN_DELAY_GOERLI, members, members, TIMELOCK_ADMIN);
    odGovernor = new ODGovernor(address(protocolToken), timelockController);
  }
}

contract DeployGoerli is DeployTestnet {
  using FixedPointMathLib for uint256;

  IBaseOracle public chainlinkEthUSDPriceFeed;

  function setUp() public virtual {
    _deployerPk = uint256(vm.envBytes32('GOERLI_DEPLOYER_PK'));
    chainId = 421_613;
  }

  // Setup oracle feeds
  function setupEnvironment() public virtual override updateParams {
    // oracle will be converted to denominated w/ camelotRelayer price source
    systemCoinOracle = new OracleForTestnet(OD_INITIAL_PRICE); // 1 OD = 1 USD 'OD / USD'

    // oracle will remain as test oracle in case camelotRelayer fails
    systemCoinOracleBackup = new OracleForTestnet(OD_INITIAL_PRICE); // 1 OD = 1 USD 'OD / USD'

    // Test tokens (various decimals for testing)
    collateral[ARB] = new MintableVoteERC20('Arbitrum', 'ARB', 18);
    collateral[WSTETH] = new MintableERC20('Wrapped liquid staked Ether 2.0', 'wstETH', 8);
    collateral[CBETH] = new MintableERC20('Coinbase Wrapped Staked ETH', 'cbETH', 8);
    collateral[RETH] = new MintableERC20('Rocket Pool ETH', 'rETH', 3);
    collateral[MAGIC] = new MintableERC20('Magic', 'MAGIC', 0);

    // to USD
    chainlinkEthUSDPriceFeed =
      chainlinkRelayerFactory.deployChainlinkRelayer(GOERLI_CHAINLINK_ETH_USD_FEED, ORACLE_INTERVAL_TEST);

    // to ETH
    OracleForTestnet _arbETHPriceFeed = new OracleForTestnet(GOERLI_ARB_ETH_PRICE_FEED);

    // denominations
    IBaseOracle _arbUSDPriceFeed =
      denominatedOracleFactory.deployDenominatedOracle(_arbETHPriceFeed, chainlinkEthUSDPriceFeed, false);

    IBaseOracle _rethETHOracle = new OracleForTestnet(0.98e18);
    IBaseOracle _rethOracle =
      denominatedOracleFactory.deployDenominatedOracle(_rethETHOracle, chainlinkEthUSDPriceFeed, false);

    IBaseOracle _magicETHOracle = new OracleForTestnet(0.00032e18);
    IBaseOracle _magicOracle =
      denominatedOracleFactory.deployDenominatedOracle(_magicETHOracle, chainlinkEthUSDPriceFeed, false);

    delayedOracle[ARB] = delayedOracleFactory.deployDelayedOracle(_arbUSDPriceFeed, ORACLE_INTERVAL_TEST);
    delayedOracle[WSTETH] = delayedOracleFactory.deployDelayedOracle(chainlinkEthUSDPriceFeed, ORACLE_INTERVAL_TEST);
    delayedOracle[CBETH] = delayedOracleFactory.deployDelayedOracle(chainlinkEthUSDPriceFeed, ORACLE_INTERVAL_TEST);
    delayedOracle[RETH] = delayedOracleFactory.deployDelayedOracle(_rethOracle, ORACLE_INTERVAL_TEST);
    delayedOracle[MAGIC] = delayedOracleFactory.deployDelayedOracle(_magicOracle, ORACLE_INTERVAL_TEST);

    // Setup collateral types
    collateralTypes.push(ARB);
    collateralTypes.push(WSTETH);
    collateralTypes.push(CBETH);
    collateralTypes.push(RETH);
    collateralTypes.push(MAGIC);
  }

  function setupPostEnvironment() public virtual override updateParams {
    // deploy Camelot liquidity pool to create market price for OD (using WSTETH for testnet, WETH for mainnet)
    ICamelotV3Factory(GOERLI_CAMELOT_V3_FACTORY).createPool(address(systemCoin), address(GOERLI_WETH));

    // confirm correct setup of pool
    address pool = camelotV3Factory.poolByPair(address(systemCoin), address(GOERLI_WETH));

    IERC20Metadata token0 = IERC20Metadata(IAlgebraPool(pool).token0());
    IERC20Metadata token1 = IERC20Metadata(IAlgebraPool(pool).token1());

    require(keccak256(abi.encodePacked('OD')) == keccak256(abi.encodePacked(token0.symbol())), '!OD');
    require(keccak256(abi.encodePacked('WETH')) == keccak256(abi.encodePacked(token1.symbol())), '!WETH');

    // initial price of each token in WAD
    uint256 initWethAmount = 1 ether;
    uint256 initODAmount = 1656.62 ether;

    // P = amount1 / amount0
    uint256 price = initWethAmount.divWadDown(initODAmount);

    // sqrtPriceX96 = sqrt(P) * 2^96
    uint256 sqrtPriceX96 = FixedPointMathLib.sqrt(price * WAD) * (2 ** 96);

    // log math
    console2.logUint((sqrtPriceX96 / (2 ** 96)) ** 2);

    // initialize pool
    IAlgebraPool(pool).initialize(uint160(sqrtPriceX96));

    // deploy Camelot relayer to retrieve price from Camelot pool
    IBaseOracle _odWethOracle = camelotRelayerFactory.deployCamelotRelayer(
      address(systemCoin), address(collateral[WSTETH]), uint32(ORACLE_INTERVAL_TEST)
    );

    // deploy denominated oracle of OD/WSTETH denominated against ETH/USD
    systemCoinOracle = denominatedOracleFactory.deployDenominatedOracle(_odWethOracle, chainlinkEthUSDPriceFeed, false);

    oracleRelayer.modifyParameters('systemCoinOracle', abi.encode(systemCoinOracle));
  }
}

contract DeployAnvil is DeployTestnet {
  function setUp() public virtual {
    _deployerPk = uint256(vm.envBytes32('ANVIL_ONE'));
    chainId = 31_337;
  }

  // Setup oracle feeds
  function setupEnvironment() public virtual override updateParams {
    // OD
    systemCoinOracle = new OracleForTestnet(OD_INITIAL_PRICE); // 1 OD = 1 USD 'OD / USD'

    // Test tokens
    collateral[ARB] = new MintableVoteERC20('Arbitrum', 'ARB', 18);
    collateral[WSTETH] = new MintableERC20('Wrapped liquid staked Ether 2.0', 'wstETH', 18);
    collateral[CBETH] = new MintableERC20('Coinbase Wrapped Staked ETH', 'cbETH', 18);
    collateral[RETH] = new MintableERC20('Rocket Pool ETH', 'rETH', 18);
    collateral[MAGIC] = new MintableERC20('Magic', 'MAGIC', 18);

    // WSTETH
    IBaseOracle _wstethUSDPriceFeed = new OracleForTestnet(1_500e18);

    // ARB
    OracleForTestnet _arbETHPriceFeed = new OracleForTestnet(0.00055e18);
    IBaseOracle _arbOracle =
      denominatedOracleFactory.deployDenominatedOracle(_arbETHPriceFeed, _wstethUSDPriceFeed, false);

    // CBETH
    IBaseOracle _cbethETHPriceFeed = new OracleForTestnet(1e18);
    IBaseOracle _cbethOracle =
      denominatedOracleFactory.deployDenominatedOracle(_cbethETHPriceFeed, _wstethUSDPriceFeed, false);

    // RETH
    IBaseOracle _rethETHOracle = new OracleForTestnet(0.98e18);
    IBaseOracle _rethOracle =
      denominatedOracleFactory.deployDenominatedOracle(_rethETHOracle, _wstethUSDPriceFeed, false);

    // MAGIC
    IBaseOracle _magicETHOracle = new OracleForTestnet(0.00032e18);
    IBaseOracle _magicOracle =
      denominatedOracleFactory.deployDenominatedOracle(_magicETHOracle, _wstethUSDPriceFeed, false);

    delayedOracle[ARB] = delayedOracleFactory.deployDelayedOracle(_arbOracle, ORACLE_INTERVAL_TEST);
    delayedOracle[WSTETH] = delayedOracleFactory.deployDelayedOracle(_wstethUSDPriceFeed, ORACLE_INTERVAL_TEST);
    delayedOracle[CBETH] = delayedOracleFactory.deployDelayedOracle(_cbethOracle, ORACLE_INTERVAL_TEST);
    delayedOracle[RETH] = delayedOracleFactory.deployDelayedOracle(_rethOracle, ORACLE_INTERVAL_TEST);
    delayedOracle[MAGIC] = delayedOracleFactory.deployDelayedOracle(_magicOracle, ORACLE_INTERVAL_TEST);

    // Setup collateral types
    collateralTypes.push(ARB);
    collateralTypes.push(WSTETH);
    collateralTypes.push(CBETH);
    collateralTypes.push(RETH);
    collateralTypes.push(MAGIC);
  }

  function setupPostEnvironment() public virtual override updateParams {}
}
