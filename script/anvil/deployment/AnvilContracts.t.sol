// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

abstract contract AnvilContracts {
  address public ChainlinkRelayerFactory_Address = 0x0aD6371dd7E9923d9968D63Eb8B9858c700abD9d;
  address public DenominatedOracleFactory_Address = 0xAA5c5496e2586F81d8d2d0B970eB85aB088639c2;
  address public DelayedOracleFactory_Address = 0xa95A928eEc085801d981d13FFE749872D8FD5bec;
  address public MintableVoteERC20_Address = 0x4458AcB1185aD869F982D51b5b0b87e23767A3A9;
  address public MintableERC20_WSTETH_Address = 0x8d375dE3D5DDde8d8caAaD6a4c31bD291756180b;
  address public MintableERC20_CBETH_Address = 0x721a1ecB9105f2335a8EA7505D343a5a09803A06;
  address public MintableERC20_RETH_Address = 0x9852795dbb01913439f534b4984fBf74aC8AfA12;
  address public DenominatedOracleChild_10_Address = 0x3D888300626c50C6Ac2054f2Dd5929a068f533aD;
  address public DenominatedOracleChild_12_Address = 0x03d6E52c8De32BB21F60A98bd188FdCb6c53227c;
  address public DenominatedOracleChild_14_Address = 0x8D9328B38DEf401f69BbD13E7fD639f8E53aAc76;
  address public DelayedOracleChild_15_Address = 0xD83E82b88884A80D04ab2b8E20e2190A7692a1a6;
  address public DelayedOracleChild_16_Address = 0xfe6e6262eE3313F30ce7ecF7bdCD8d5aCFB80f46;
  address public DelayedOracleChild_17_Address = 0x6a252496936D787a33CF10f798769809DbaF9dAB;
  address public DelayedOracleChild_18_Address = 0xBf6685AcCee8BabE4800F7c135eF7bEFB2875472;
  address public SystemCoin_Address = 0x82BBAA3B0982D88741B275aE1752DB85CAfe3c65;
  address public ProtocolToken_Address = 0x084815D1330eCC3eF94193a19Ec222C0C73dFf2d;
  address public TimelockController_Address = 0x564Db7a11653228164FD03BcA60465270E67b3d7;
  address public ODGovernor_Address = 0x9abb5861e3a1eDF19C51F8Ac74A81782e94F8FdC;
  address public SAFEEngine_Address = 0xaE2abbDE6c9829141675fA0A629a675badbb0d9F;
  address public OracleRelayer_Address = 0x8B342f4Ddcc71Af65e4D2dA9CD00cc0E945cFD12;
  address public SurplusAuctionHouse_Address = 0xE2307e3710d108ceC7a4722a020a050681c835b3;
  address public DebtAuctionHouse_Address = 0xD28F3246f047Efd4059B24FA1fa587eD9fa3e77F;
  address public AccountingEngine_Address = 0x15F2ea83eB97ede71d84Bd04fFF29444f6b7cd52;
  address public LiquidationEngine_Address = 0x0B32a3F8f5b7E5d315b9E52E640a49A89d89c820;
  address public CollateralAuctionHouseFactory_Address = 0xF357118EBd576f3C812c7875B1A1651a7f140E9C;
  address public CoinJoin_Address = 0x519b05b3655F4b89731B677d64CEcf761f4076f6;
  address public CollateralJoinFactory_Address = 0x057cD3082EfED32d5C907801BF3628B27D88fD80;
  address public TaxCollector_Address = 0xb6057e08a11da09a998985874FE2119e98dB3D5D;
  address public StabilityFeeTreasury_Address = 0xad203b3144f8c09a20532957174fc0366291643c;
  address public GlobalSettlement_Address = 0x91A1EeE63f300B8f41AE6AF67eDEa2e2ed8c3f79;
  address public PostSettlementSurplusAuctionHouse_Address = 0xBe6Eb4ACB499f992ba2DaC7CAD59d56DA9e0D823;
  address public SettlementSurplusAuctioneer_Address = 0x54287AaB4D98eA51a3B1FBceE56dAf27E04a56A6;
  address public PIDController_Address = 0xCA87833e830652C2ab07E1e03eBa4F2c246D3b58;
  address public PIDRateSetter_Address = 0x9Bb65b12162a51413272d10399282E730822Df44;
  address public AccountingJob_Address = 0x834Ea01e45F9b5365314358159d92d134d89feEb;
  address public LiquidationJob_Address = 0x8D75F9F7f4F4C4eFAB9402261bC864f21DF0c649;
  address public OracleJob_Address = 0x0dEe24C99e8dF7f0E058F4F48f228CC07DB704Fc;
  address public CollateralJoinChild_0x4152420000000000000000000000000000000000000000000000000000000000_Address =
    0x7BB4eB082E8D588F5d7e7753f3c641Eb1F9F2b45;
  address public
    CollateralAuctionHouseChild_0x4152420000000000000000000000000000000000000000000000000000000000_Address =
      0x7D09E9F0C2d40593faDa26B6d48359C171e51802;
  address public CollateralJoinChild_0x5753544554480000000000000000000000000000000000000000000000000000_Address =
    0xE8AA884B53D08E1bcCd35c32eD0095B4294B8bdE;
  address public
    CollateralAuctionHouseChild_0x5753544554480000000000000000000000000000000000000000000000000000_Address =
      0x88bd8eE84eE19D58dd94e45a219509dcD171cB27;
  address public CollateralJoinChild_0x4342455448000000000000000000000000000000000000000000000000000000_Address =
    0x6bC7B91ef1147b99519ED18127065de942c90356;
  address public
    CollateralAuctionHouseChild_0x4342455448000000000000000000000000000000000000000000000000000000_Address =
      0xEDB78CC2669B68e51EA18aB4DD2689Cd105BC2Be;
  address public CollateralJoinChild_0x5245544800000000000000000000000000000000000000000000000000000000_Address =
    0x35EFcF6822f9e4F518059419dEAf97B22C993129;
  address public
    CollateralAuctionHouseChild_0x5245544800000000000000000000000000000000000000000000000000000000_Address =
      0xcF6c3D8CB9F82C5988477abAe67915305AfBf2A1;
  address public Vault721_Address = 0x67Fc5Aa53440518DdbAd4B381fD4b86fFD77B776;
  address public ODSafeManager_Address = 0x2e13f7644014F6E934E314F0371585845de7B986;
  address public NFTRenderer_Address = 0xf4e55515952BdAb2aeB4010f777E802D61eB384f;
  address public BasicActions_Address = 0xe519389F8c262d4301Fd2830196FB7D0021daf59;
  address public DebtBidActions_Address = 0xcE7e5946C14Cdd1f8de4473dB9c20fd65EBd47d0;
  address public SurplusBidActions_Address = 0xA496E0071780CF57cd699cb1D5Ac0CdCD6cCD673;
  address public CollateralBidActions_Address = 0x4E76FbE44fa5Dae076a7f4f676250e7941421fbA;
  address public PostSettlementSurplusBidActions_Address = 0x00B0517de6b2b09aBD3a7B69d66D85eFdb2c7d94;
  address public GlobalSettlementActions_Address = 0x49AeF2C4005Bf572665b09014A563B5b9E46Df21;
  address public RewardedActions_Address = 0xa9efDEf197130B945462163a0B852019BA529a66;
}
