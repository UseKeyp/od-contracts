// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {Authorizable} from '@contracts/utils/Authorizable.sol';

// solhint-disable
contract Coin is Authorizable {
  // --- ERC20 Data ---
  // The name of this coin
  string public name;
  // The symbol of this coin
  string public symbol;
  // The version of this Coin contract
  string public version = '1';
  // The number of decimals that this coin has
  uint8 public constant decimals = 18;

  // The id of the chain where this coin was deployed
  uint256 public chainId;
  // The total supply of this coin
  uint256 public totalSupply;

  // Mapping of coin balances
  mapping(address => uint256) public balanceOf;
  // Mapping of allowances
  mapping(address => mapping(address => uint256)) public allowance;
  // Mapping of nonces used for permits
  mapping(address => uint256) public nonces;

  // --- Events ---
  event Approval(address indexed src, address indexed guy, uint256 amount);
  event Transfer(address indexed src, address indexed dst, uint256 amount);

  // --- EIP712 niceties ---
  bytes32 public DOMAIN_SEPARATOR;
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

  // --- Init ---
  constructor(string memory name_, string memory symbol_, uint256 chainId_) Authorizable(msg.sender) {
    name = name_;
    symbol = symbol_;
    chainId = chainId_;
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId_,
        address(this)
      )
    );
  }

  // --- Token ---
  /**
   * @notice Transfer coins to another address
   * @param dst The address to transfer coins to
   * @param amount The amount of coins to transfer
   */
  function transfer(address dst, uint256 amount) external returns (bool) {
    return transferFrom(msg.sender, dst, amount);
  }

  /**
   * @notice Transfer coins from a source address to a destination address (if allowed)
   * @param src The address from which to transfer coins
   * @param dst The address that will receive the coins
   * @param amount The amount of coins to transfer
   */
  function transferFrom(address src, address dst, uint256 amount) public returns (bool) {
    require(dst != address(0), 'Coin/null-dst');
    require(dst != address(this), 'Coin/dst-cannot-be-this-contract');
    require(balanceOf[src] >= amount, 'Coin/insufficient-balance');
    if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
      require(allowance[src][msg.sender] >= amount, 'Coin/insufficient-allowance');
      allowance[src][msg.sender] = allowance[src][msg.sender] - amount;
    }
    balanceOf[src] = balanceOf[src] - amount;
    balanceOf[dst] = balanceOf[dst] + amount;
    emit Transfer(src, dst, amount);
    return true;
  }

  /**
   * @notice Mint new coins
   * @param usr The address for which to mint coins
   * @param amount The amount of coins to mint
   */
  function mint(address usr, uint256 amount) external isAuthorized {
    balanceOf[usr] = balanceOf[usr] + amount;
    totalSupply = totalSupply + amount;
    emit Transfer(address(0), usr, amount);
  }

  /**
   * @notice Burn coins from an address
   * @param usr The address that will have its coins burned
   * @param amount The amount of coins to burn
   */
  function burn(address usr, uint256 amount) external {
    require(balanceOf[usr] >= amount, 'Coin/insufficient-balance');
    if (usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max) {
      require(allowance[usr][msg.sender] >= amount, 'Coin/insufficient-allowance');
      allowance[usr][msg.sender] = allowance[usr][msg.sender] - amount;
    }
    balanceOf[usr] = balanceOf[usr] - amount;
    totalSupply = totalSupply - amount;
    emit Transfer(usr, address(0), amount);
  }

  /**
   * @notice Change the transfer/burn allowance that another address has on your behalf
   * @param usr The address whose allowance is changed
   * @param amount The new total allowance for the usr
   */
  function approve(address usr, uint256 amount) external returns (bool) {
    allowance[msg.sender][usr] = amount;
    emit Approval(msg.sender, usr, amount);
    return true;
  }

  // --- Alias ---
  /**
   * @notice Send coins to another address
   * @param usr The address to send tokens to
   * @param amount The amount of coins to send
   */
  function push(address usr, uint256 amount) external {
    transferFrom(msg.sender, usr, amount);
  }

  /**
   * @notice Transfer coins from another address to your address
   * @param usr The address to take coins from
   * @param amount The amount of coins to take from the usr
   */
  function pull(address usr, uint256 amount) external {
    transferFrom(usr, msg.sender, amount);
  }

  /**
   * @notice Transfer coins from another address to a destination address (if allowed)
   * @param src The address to transfer coins from
   * @param dst The address to transfer coins to
   * @param amount The amount of coins to transfer
   */
  function move(address src, address dst, uint256 amount) external {
    transferFrom(src, dst, amount);
  }

  // --- Approve by signature ---
  /**
   * @notice Submit a signed message that modifies an allowance for a specific address
   */
  function permit(
    address holder,
    address spender,
    uint256 nonce,
    uint256 expiry,
    bool allowed,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01', DOMAIN_SEPARATOR, keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed))
      )
    );

    require(holder != address(0), 'Coin/invalid-address-0');
    require(holder == ecrecover(digest, v, r, s), 'Coin/invalid-permit');
    require(expiry == 0 || block.timestamp <= expiry, 'Coin/permit-expired');
    require(nonce == nonces[holder]++, 'Coin/invalid-nonce');
    uint256 wad = allowed ? type(uint256).max : 0;
    allowance[holder][spender] = wad;
    emit Approval(holder, spender, wad);
  }
}