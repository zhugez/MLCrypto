pragma solidity ^0.4.15;

contract ELTCoinToken {
  function transfer(address to, uint256 value) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a end timestamp, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  uint256 public constant RATE_CHANGE_THRESHOLD = 30000000000000;

  // The token being sold
  ELTCoinToken public token;

  // end timestamp where investments are allowed (both inclusive)
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many wei for a token unit
  uint256 public startRate;

  // current rate
  uint256 public currentRate;

  // maximum rate
  uint256 public maxRate;

  // the minimum transaction threshold in wei
  uint256 public minThreshold;

  // amount of raised money in wei
  uint256 public weiRaised;

  // amount of tokens sold
  uint256 public tokensSold;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event WeiTransfer(address indexed receiver, uint256 amount);

  function Crowdsale(
    address _contractAddress, uint256 _endTime, uint256 _startRate, uint256 _minThreshold, address _wallet) {
    // require(_endTime >= now);
    require(_wallet != 0x0);

    token = ELTCoinToken(_contractAddress);
    endTime = _endTime;
    startRate = _startRate;
    currentRate = _startRate;
    maxRate = startRate.mul(10);
    wallet = _wallet;
    minThreshold = _minThreshold;
  }

  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    require(weiAmount >= minThreshold);

    uint256 weiToAllocate = weiAmount;

    uint256 tokensTotal = 0;

    while (weiToAllocate > 0) {
      currentRate = tokensSold.div(RATE_CHANGE_THRESHOLD).mul(startRate).add(startRate);

      if (currentRate > maxRate) {
        currentRate = maxRate;
      }

      // Round to an integer number of tokens
      weiToAllocate = weiToAllocate.sub(weiToAllocate % currentRate);

      uint256 remainingTokens = RATE_CHANGE_THRESHOLD.sub(tokensSold % RATE_CHANGE_THRESHOLD);

      uint256 tokens = weiToAllocate.div(currentRate) > remainingTokens ? remainingTokens : weiToAllocate.div(currentRate);

      tokensTotal = tokensTotal.add(tokens);
      tokensSold = tokensSold.add(tokens);

      weiToAllocate = weiToAllocate.sub(tokens.mul(currentRate));
    }

    weiRaised = weiRaised.add(weiAmount);

    require(token.transfer(beneficiary, tokensTotal));

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokensTotal);

    forwardFunds(weiAmount);
  }

  function forwardFunds(uint256 amount) internal {
    wallet.transfer(amount);
    WeiTransfer(wallet, amount);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
}

/**
 * @title IndividualCappedCrowdsale
 * @dev Extension of Crowdsale with an individual cap
 */
contract IndividualCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint public constant GAS_LIMIT_IN_WEI = 50000000000 wei;

  // The maximum wei amount a user can spend during this sale
  uint256 public capPerAddress;

  mapping(address=>uint) public participated;

  function IndividualCappedCrowdsale(uint256 _capPerAddress) {
    // require(capPerAddress > 0);
    capPerAddress = _capPerAddress;
  }

  /**
    * @dev overriding CappedCrowdsale#validPurchase to add an individual cap
    * @return true if investors can buy at the moment
    */
  function validPurchase() internal returns (bool) {
    require(tx.gasprice <= GAS_LIMIT_IN_WEI);
    participated[msg.sender] = participated[msg.sender].add(msg.value);
    return super.validPurchase() && participated[msg.sender] <= capPerAddress;
  }
}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }
}

contract ELTCoinCrowdsale is Ownable, CappedCrowdsale, IndividualCappedCrowdsale {
  function ELTCoinCrowdsale(address _coinAddress, uint256 _endTime, uint256 _rate, uint256 _cap, uint256 _minThreshold, uint256 _capPerAddress, address _wallet)
    IndividualCappedCrowdsale(_capPerAddress)
    CappedCrowdsale(_cap)
    Crowdsale(_coinAddress, _endTime, _rate, _minThreshold, _wallet)
  {

  }

  /**
  * @dev Transfer the unsold tokens to the owner main wallet
  * @dev Only for owner
  */
  function drainRemainingToken ()
    public
    onlyOwner
  {
      require(hasEnded());
      token.transfer(owner, token.balanceOf(this));
  }

  function setMaxRate(uint256 _maxRate) public onlyOwner {
    maxRate = _maxRate;
  }
}
