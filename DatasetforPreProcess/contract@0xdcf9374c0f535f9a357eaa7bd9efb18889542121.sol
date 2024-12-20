pragma solidity ^0.4.19;

/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol" : start
 *************************************************************************/


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol" : start
 *************************************************************************/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "./StandardToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}
/*************************************************************************
 * import "./StandardToken.sol" : end
 *************************************************************************/



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol" : end
 *************************************************************************/

/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "../../lifecycle/Pausable.sol" : start
 *************************************************************************/





/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
/*************************************************************************
 * import "../../lifecycle/Pausable.sol" : end
 *************************************************************************/


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/ownership/CanReclaimToken.sol" : start
 *************************************************************************/



/*************************************************************************
 * import "../token/ERC20/SafeERC20.sol" : start
 *************************************************************************/





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
/*************************************************************************
 * import "../token/ERC20/SafeERC20.sol" : end
 *************************************************************************/


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}
/*************************************************************************
 * import "../node_modules/zeppelin-solidity/contracts/ownership/CanReclaimToken.sol" : end
 *************************************************************************/


contract CanReclaimEther is Ownable {
  function claim() public onlyOwner {
    owner.transfer(this.balance);
  }
}


contract ZNA is StandardToken, Ownable, PausableToken {

    using SafeMath for uint256;

    uint256 public MAX_TOTAL;

    function ZNA (uint256 maxAmount) public {
      MAX_TOTAL = maxAmount;
    }

   /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
   function mint(address _to, uint256 _amount)
   public onlyOwner returns (bool) {
     totalSupply_ = totalSupply_.add(_amount);
     require(totalSupply_ <= MAX_TOTAL);
     balances[_to] = balances[_to].add(_amount);
     emit Transfer(address(0), _to, _amount);
     return true;
   }

   string public name = "ZNA Token";
   string public symbol = "ZNA";
   uint8  public decimals = 18;
}


contract ZenomeCrowdsale is Ownable, CanReclaimToken, CanReclaimEther {

  using SafeMath for uint256;

  struct TokenPool {
    address minter;
    uint256 amount;
    uint256 safecap;
    uint256 total;
  }

  ZNA public token;

  TokenPool public for_sale;
  TokenPool public for_rewards;
  TokenPool public for_longterm;
  /* solhint-disable */
  /* solhint-enable */

  function ZenomeCrowdsale () public {
    for_sale.total = 1575*10**22;
    for_rewards.total = 1050*10**22;
    for_longterm.total = 875*10**22;

    uint256 MAX_TOTAL = for_sale.total
      .add(for_rewards.total)
      .add(for_longterm.total);

    token = new ZNA(MAX_TOTAL);
  }

 /**
  *  Setting Minter interface
  */
  function setSaleMinter (address minter, uint safecap) public onlyOwner { setMinter(for_sale, minter, safecap); }

  function setRewardMinter (address minter, uint safecap) public onlyOwner {
    require(safecap <= for_sale.amount);
    setMinter(for_rewards, minter, safecap);
  }

  function setLongtermMinter (address minter, uint safecap) public onlyOwner {
    require(for_sale.amount > 1400*10**22);
    setMinter(for_longterm, minter, safecap);
  }

  function transferTokenOwnership (address newOwner) public onlyOwner {
    require(newOwner != address(0));
    token.transferOwnership(newOwner);
  }

  function pauseToken() public onlyOwner { token.pause(); }
  function unpauseToken() public onlyOwner { token.unpause(); }

  /**
   *  Minter's interface
   */
  function mintSoldTokens (address to, uint256 amount) public {
    mintTokens(for_sale, to, amount);
  }

  function mintRewardTokens (address to, uint256 amount) public {
    mintTokens(for_rewards, to, amount);
  }

  function mintLongTermTokens (address to, uint256 amount) public {
    mintTokens(for_longterm, to, amount);
  }

  /**
   * INTERNAL FUNCTIONS

   "Of course, calls to internal functions use the internal calling convention,
    which means that all internal types can be passed and memory types will be
    passed by reference and not copied."

    https://solidity.readthedocs.io/en/develop/contracts.html#libraries
  */
  /**
   *  Set minter and a safe cap in a single call.
   *  IT MUST NOT BE VIEW!
   */
  function setMinter (TokenPool storage pool, address minter, uint256 safecap)
  internal onlyOwner {
    require(safecap <= pool.total);
    pool.minter = minter;
    pool.safecap = safecap;
  }

  /**
   *
   */
  function mintTokens (TokenPool storage pool, address to, uint256 amount )
  internal {
    require(msg.sender == pool.minter);
    uint256 new_amount = pool.amount.add(amount);
    require(new_amount <= pool.safecap);

    pool.amount = new_amount;
    token.mint(to, amount);
  }

}
