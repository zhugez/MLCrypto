pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Proxy {
    using SafeMath for uint256;
    uint256 public contribution = 0;
    ETH_8 public eth_8;
    
    constructor() public {
        eth_8 = ETH_8(msg.sender);
    }
    
    function() public payable {
        
        if(msg.value == 0) {
            // Dividends
            eth_8.withdrawDividends(msg.sender);
            return;
        }
        
        address newReferrer = _bytesToAddress(msg.data);
        // Deposit
        contribution = contribution.add(msg.value);
        address(eth_8).transfer(msg.value);
        eth_8.doInvest(msg.sender, msg.value, newReferrer);
    }
    
    function _bytesToAddress(bytes data) private pure returns(address addr) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := mload(add(data, 20)) 
        }
    }
}

contract ETH_8 {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;               // 100%
    uint256[] public DAILY_INTEREST = [111, 133, 222, 333, 444];        // 1.11%, 2.22%, 3.33%, 4.44%
    uint256 public MARKETING_AND_TEAM_FEE = 1000;                       // 10%
    uint256 public referralPercents = 1000;                             // 10%
    uint256 constant public MAX_DIVIDEND_RATE = 25000;                  // 250%
    uint256 constant public MINIMUM_DEPOSIT = 100 finney;               // 0.1 eth
    uint256 public wave = 0;
    uint256 public totalInvest = 0;
    uint256 public totalDividend = 0;
    mapping(address => bool) public isProxy;

    struct Deposit {
        uint256 amount;
        uint256 interest;
        uint256 withdrawedRate;
    }

    struct User {
        address referrer;
        uint256 referralAmount;
        uint256 firstTime;
        uint256 lastPayment;
        Deposit[] deposits;
    }

    address public marketingAndTechnicalSupport = 0xC93C7F3Ac689B822C3e9d09b9cA8934e54cf1D70;
    address public owner = 0xbBdE48b0c31dA0DD601DA38F31dcf92b04f42588;
    mapping(uint256 => mapping(address => User)) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event DepositDividendPayed(address indexed investor, uint256 indexed index, uint256 deposit, uint256 totalPayed, uint256 dividend);
    event FeePayed(address indexed investor, uint256 amount);
    event BalanceChanged(uint256 balance);
    event NewWave();
    
    function() public payable {
        require(isProxy[msg.sender]);
    }

    function withdrawDividends(address from) public {
        require(isProxy[msg.sender]);
        uint256 dividendsSum = getDividends(from);
        require(dividendsSum > 0);
        
        if (address(this).balance <= dividendsSum) {
            wave = wave.add(1);
            totalInvest = 0;
            dividendsSum = address(this).balance;
            emit NewWave();
        }
        from.transfer(dividendsSum);
        emit UserDividendPayed(from, dividendsSum);
        emit BalanceChanged(address(this).balance);
    }
    
    function getDividends(address wallet) internal returns(uint256 sum) {
        User storage user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawRate = dividendRate(wallet, i);
            user.deposits[i].withdrawedRate = user.deposits[i].withdrawedRate.add(withdrawRate);
            sum = sum.add(user.deposits[i].amount.mul(withdrawRate).div(ONE_HUNDRED_PERCENTS));
            emit DepositDividendPayed(
                wallet,
                i,
                user.deposits[i].amount,
                user.deposits[i].amount.mul(user.deposits[i].withdrawedRate.div(ONE_HUNDRED_PERCENTS)),
                user.deposits[i].amount.mul(withdrawRate.div(ONE_HUNDRED_PERCENTS))
            );
        }
        user.lastPayment = now;
        totalDividend = totalDividend.add(sum);
    }

    function dividendRate(address wallet, uint256 index) internal view returns(uint256 rate) {
        User memory user = users[wave][wallet];
        uint256 duration = now.sub(user.lastPayment);
        rate = user.deposits[index].interest.mul(duration).div(1 days);
        uint256 leftRate = MAX_DIVIDEND_RATE.sub(user.deposits[index].withdrawedRate);
        rate = min(rate, leftRate);
    }

    function doInvest(address from, uint256 investment, address newReferrer) public {
        require(isProxy[msg.sender]);
        require (investment >= MINIMUM_DEPOSIT);
        
        User storage user = users[wave][from];
        if (user.firstTime == 0) {
            user.firstTime = now;
            user.lastPayment = now;
            emit InvestorAdded(from);
        }

        // Add referral if possible
        if (user.referrer == address(0)
            && user.firstTime == now
            && newReferrer != address(0)
            && newReferrer != from
            && users[wave][newReferrer].firstTime > 0
        ) {
            user.referrer = newReferrer;
            emit ReferrerAdded(from, newReferrer);
        }
        
        // Referrers fees
        if (user.referrer != address(0)) {
            uint256 refAmount = investment.mul(referralPercents).div(ONE_HUNDRED_PERCENTS);
            users[wave][user.referrer].referralAmount = users[wave][user.referrer].referralAmount.add(investment);
            user.referrer.transfer(refAmount);
        }
        
        // Reinvest
        investment = investment.add(getDividends(from));
        
        totalInvest = totalInvest.add(investment);
        
        // Create deposit
        user.deposits.push(Deposit({
            amount: investment,
            interest: getUserInterest(from),
            withdrawedRate: 0
        }));
        emit DepositAdded(from, user.deposits.length, investment);

        // Marketing and Team fee
        uint256 marketingAndTeamFee = investment.mul(MARKETING_AND_TEAM_FEE).div(ONE_HUNDRED_PERCENTS);
        marketingAndTechnicalSupport.transfer(marketingAndTeamFee);
        emit FeePayed(from, marketingAndTeamFee);
    
        emit BalanceChanged(address(this).balance);
    }
    
    function getUserInterest(address wallet) public view returns (uint256) {
        User memory user = users[wave][wallet];
        if (user.referralAmount < 1 ether) {
            if(user.referrer == address(0)) return DAILY_INTEREST[0];
            return DAILY_INTEREST[1];
        } else if (user.referralAmount < 10 ether) {
            return DAILY_INTEREST[2];
        } else if (user.referralAmount < 20 ether) {
            return DAILY_INTEREST[3];
        } else {
            return DAILY_INTEREST[4];
        }
    }
    
    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a < b) return a;
        return b;
    }
    
    function depositForUser(address wallet) external view returns(uint256 sum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            sum = sum.add(user.deposits[i].amount);
        }
    }
    
    function dividendsSumForUser(address wallet) external view returns(uint256 dividendsSum) {
        User memory user = users[wave][wallet];
        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 withdrawAmount = user.deposits[i].amount.mul(dividendRate(wallet, i)).div(ONE_HUNDRED_PERCENTS);
            dividendsSum = dividendsSum.add(withdrawAmount);
        }
        dividendsSum = min(dividendsSum, address(this).balance);
    }
    
    function changeInterest(uint256[] interestList) external {
        require(address(msg.sender) == owner);
        DAILY_INTEREST = interestList;
    }
    
    function changeTeamFee(uint256 feeRate) external {
        require(address(msg.sender) == owner);
        MARKETING_AND_TEAM_FEE = feeRate;
    }
    
    function virtualInvest(address from, uint256 amount) public {
        require(address(msg.sender) == owner);
        
        User storage user = users[wave][from];
        if (user.firstTime == 0) {
            user.firstTime = now;
            user.lastPayment = now;
            emit InvestorAdded(from);
        }
        
        // Reinvest
        amount = amount.add(getDividends(from));
        
        user.deposits.push(Deposit({
            amount: amount,
            interest: getUserInterest(from),
            withdrawedRate: 0
        }));
        emit DepositAdded(from, user.deposits.length, amount);
    }
    
    function createProxy() external {
        require(msg.sender == owner);
        Proxy newProxy = new Proxy();
        isProxy[address(newProxy)] = true;
    }
}
