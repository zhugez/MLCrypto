pragma solidity ^0.4.25;

//This smart-contract was developed exclusively for kassa.network
//if you need smart-contracts like this, more complicated or more simple, please contact vijaya108@pm.me

contract Ownable 
{
    address public laxmi;
    address public newLaxmi;
    
    constructor() public 
    {
        laxmi = msg.sender;
    }

    modifier onlyLaxmi() 
    {
        require(msg.sender == laxmi, "Can used only by owner");
        _;
    }

    function changeLaxmi(address _laxmi) onlyLaxmi public 
    {
        require(_laxmi != 0, "Please provide new owner address");
        newLaxmi = _laxmi;
    }
    
    function confirmLaxmi() public 
    {
        require(newLaxmi == msg.sender, "Please call from new owner");
        laxmi = newLaxmi;
        delete newLaxmi;
    }
}

library SafeMath 
{

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {
        if (_a == 0) { return 0; }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        return _a / _b;
    }


    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        assert(_b <= _a);
        return _a - _b;
    }


    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


contract KassaNetwork is Ownable 
{
    using SafeMath for uint;

    string  public constant name    = 'Kassa 400/100';
    uint public startTimestamp = now;

    uint public constant procKoef = 10000;
    uint public constant perDay = 50;
    uint public constant ownerFee = 500;
    uint[5] public bonusReferrer = [500, 100, 100, 100, 200];

    uint public constant procReturn = 9000;


    uint public constant maxDepositDays = 400;


    uint public constant minimalDeposit = 1 ether;
    uint public constant maximalDepositStart = 50 ether;
    uint public constant maximalDepositFinish = 100 ether;

    uint public constant minimalDepositForBonusReferrer = 0.015 ether;


    uint public constant dayLimitStart = 50 ether;


    uint public constant progressProcKoef = 100;
    uint public constant dayLimitProgressProc = 2;
    uint public constant maxDepositProgressProc = 1;


    uint public countInvestors = 0;
    uint public totalInvest = 0;
    uint public totalPenalty = 0;
    uint public totalSelfInvest = 0;
    uint public totalPaid = 0;

    event LogInvestment(address _addr, uint _value, bytes _refData);
    event LogTransfer(address _addr, uint _amount, uint _contactBalance);
    event LogSelfInvestment(uint _value);

    event LogPreparePayment(address _addr, uint _totalInteres, uint _paidInteres, uint _amount);
    event LogSkipPreparePayment(address _addr, uint _totalInteres, uint _paidInteres);

    event LogPreparePaymentReferrer(address _addr, uint _totalReferrals, uint _paidReferrals, uint _amount);
    event LogSkipPreparePaymentReferrer(address _addr, uint _totalReferrals, uint _paidReferrals);

    event LogMinimalDepositPayment(address _addr, uint _money, uint _totalPenalty);
    event LogPenaltyPayment(address _addr, uint currentSenderDeposit, uint referrerAdressLength, address _referrer, uint currentReferrerDeposit, uint _money, uint _sendBackAmount, uint _totalPenalty);
    event LogExceededRestDepositPerDay(address _addr, address _referrer, uint _money, uint _nDay, uint _restDepositPerDay, uint _badDeposit, uint _sendBackAmount, uint _totalPenalty, uint _willDeposit);

    event LogUsedRestDepositPerDay(address _addr, address _referrer, uint _money, uint _nDay, uint _restDepositPerDay, uint _realDeposit, uint _usedDepositPerDay);
    event LogCalcBonusReferrer(address _referrer, uint _money, uint _index, uint _bonusReferrer, uint _amountReferrer, address _nextReferrer);


    struct User
    {
        uint balance;
        uint paidInteres;
        uint timestamp;
        uint countReferrals;
        uint[5] countReferralsByLevel;
        uint earnOnReferrals;
        uint paidReferrals;
        address referrer;
    }

    mapping (address => User) private user;

    mapping (uint => uint) private usedDeposit;

    function getInteres(address addr) private view returns(uint interes) 
    {
        uint diffDays = getNDay(user[addr].timestamp);

        if( diffDays > maxDepositDays ) diffDays = maxDepositDays;

        interes = user[addr].balance.mul(perDay).mul(diffDays).div(procKoef);
    }

    function getUser(address addr) public view returns(uint balance, uint timestamp, uint paidInteres, uint totalInteres, uint countReferrals, uint[5] countReferralsByLevel, uint earnOnReferrals, uint paidReferrals, address referrer) 
    {
        address a = addr;
        return (
            user[a].balance,
            user[a].timestamp,
            user[a].paidInteres,
            getInteres(a),
            user[a].countReferrals,
            user[a].countReferralsByLevel,
            user[a].earnOnReferrals,
            user[a].paidReferrals,
            user[a].referrer
        );
    }

    function getCurrentDay() public view returns(uint nday) 
    {
        nday = getNDay(startTimestamp);
    }

    function getNDay(uint date) public view returns(uint nday) 
    {
        uint diffTime = date > 0 ? now.sub(date) : 0;

        nday = diffTime.div(24 hours);
    }

    function getCurrentDayDepositLimit() public view returns(uint limit) 
    {
        uint nDay = getCurrentDay();
        
        uint dayDepositLimit = getDayDepositLimit(nDay);

        if (dayDepositLimit <= maximalDepositFinish) 
        {
            limit = getDayDepositLimit(nDay);
        } 
        else 
        {
            limit = maximalDepositFinish;
        }
    }


    function calcProgress(uint start, uint proc, uint nDay) public pure returns(uint res) 
    {
        uint s = start;

        for (uint i = 0; i < nDay; i++)
        {
            s = s.mul(progressProcKoef + proc).div(progressProcKoef);
        }

        return s;
    }

    function getDayDepositLimit(uint nDay) public pure returns(uint limit) 
    {                         
        return calcProgress(dayLimitStart, dayLimitProgressProc, nDay );
    }

    function getMaximalDeposit(uint nDay) public pure returns(uint limit) 
    {                 
        return calcProgress(maximalDepositStart, maxDepositProgressProc, nDay );
    }

    function getCurrentDayRestDepositLimit() public view returns(uint restLimit) 
    {
        uint nDay = getCurrentDay();

        restLimit = getDayRestDepositLimit(nDay);
    }

    function getDayRestDepositLimit(uint nDay) public view returns(uint restLimit) 
    {
        restLimit = getCurrentDayDepositLimit().sub(usedDeposit[nDay]);
    }


    function getCurrentMaximalDeposit() public view returns(uint maximalDeposit) 
    {
        uint nDay = getCurrentDay();

        maximalDeposit = getMaximalDeposit(nDay);
        
        if (totalInvest > 3000 ether)
        {
            maximalDeposit = 0;
        }
    }


    function() external payable 
    {
        emit LogInvestment(msg.sender, msg.value, msg.data);
        processPayment(msg.value, msg.data);
    }

    function processPayment(uint moneyValue, bytes refData) private
    {
        if (msg.sender == laxmi) 
        { 
            totalSelfInvest = totalSelfInvest.add(moneyValue);
            emit LogSelfInvestment(moneyValue);
            return; 
        }

        if (moneyValue == 0) 
        { 
            preparePayment();
            return; 
        }

        if (moneyValue < minimalDeposit) 
        { 
            totalPenalty = totalPenalty.add(moneyValue);
            emit LogMinimalDepositPayment(msg.sender, moneyValue, totalPenalty);
            return; 
        }

        address referrer = bytesToAddress(refData);

        if (user[msg.sender].balance > 0 || 
            refData.length != 20 || 
            moneyValue > getCurrentMaximalDeposit() ||
            referrer != laxmi &&
              (
                 user[referrer].balance <= 0 || 
                 referrer == msg.sender) 
              )
        { 
            uint amount = moneyValue.mul(procReturn).div(procKoef);

            totalPenalty = totalPenalty.add(moneyValue.sub(amount));

            emit LogPenaltyPayment(msg.sender, user[msg.sender].balance, refData.length, referrer, user[referrer].balance, moneyValue, amount, totalPenalty);

            msg.sender.transfer(amount);

            return; 
        }



        uint nDay = getCurrentDay();

        uint restDepositPerDay = getDayRestDepositLimit(nDay);

        uint addDeposit = moneyValue;


        if (moneyValue > restDepositPerDay)
        {
            uint returnDeposit = moneyValue.sub(restDepositPerDay);

            uint returnAmount = returnDeposit.mul(procReturn).div(procKoef);

            addDeposit = addDeposit.sub(returnDeposit);

            totalPenalty = totalPenalty.add(returnDeposit.sub(returnAmount));

            emit LogExceededRestDepositPerDay(msg.sender, referrer, moneyValue, nDay, restDepositPerDay, returnDeposit, returnAmount, totalPenalty, addDeposit);

            msg.sender.transfer(returnAmount);
        }

        usedDeposit[nDay] = usedDeposit[nDay].add(addDeposit);

        emit LogUsedRestDepositPerDay(msg.sender, referrer, moneyValue, nDay, restDepositPerDay, addDeposit, usedDeposit[nDay]);


        registerInvestor(referrer);
        sendOwnerFee(addDeposit);
        calcBonusReferrers(referrer, addDeposit);
        updateInvestBalance(addDeposit);
    }


    function registerInvestor(address referrer) private 
    {
        user[msg.sender].timestamp = now;
        countInvestors++;

        user[msg.sender].referrer = referrer;
        
        //user[referrer].countReferrals++;
        countReferralsByLevel(referrer, 0);
    }
    
    function countReferralsByLevel(address referrer, uint level) private
    {
        if (level > 5) 
        {
            return;
        }
        
        user[referrer].countReferralsByLevel[level]++;
        
        address _nextReferrer = user[referrer].referrer;
        
        if (_nextReferrer != 0) 
        {
            level++;
            countReferralsByLevel(_nextReferrer, level);
        }
        
        return;
    }

    function sendOwnerFee(uint addDeposit) private 
    {
        transfer(laxmi, addDeposit.mul(ownerFee).div(procKoef));
    }

    function calcBonusReferrers(address referrer, uint addDeposit) private 
    {
        for (uint i = 0; i < bonusReferrer.length && referrer != 0; i++)
        {
            uint amountReferrer = addDeposit.mul(bonusReferrer[i]).div(procKoef);

            address nextReferrer = user[referrer].referrer;

            emit LogCalcBonusReferrer(referrer, addDeposit, i, bonusReferrer[i], amountReferrer, nextReferrer);

            preparePaymentReferrer(referrer, amountReferrer);

            referrer = nextReferrer;
        }
    }


    function preparePaymentReferrer(address referrer, uint amountReferrer) private 
    {
        user[referrer].earnOnReferrals = user[referrer].earnOnReferrals.add(amountReferrer);

        uint totalReferrals = user[referrer].earnOnReferrals;
        uint paidReferrals = user[referrer].paidReferrals;


        if (totalReferrals >= paidReferrals.add(minimalDepositForBonusReferrer)) 
        {
            uint amount = totalReferrals.sub(paidReferrals);

            user[referrer].paidReferrals = user[referrer].paidReferrals.add(amount);

            emit LogPreparePaymentReferrer(referrer, totalReferrals, paidReferrals, amount);

            transfer(referrer, amount);
        }
        else
        {
            emit LogSkipPreparePaymentReferrer(referrer, totalReferrals, paidReferrals);
        }

    }


    function preparePayment() public 
    {
        uint totalInteres = getInteres(msg.sender);
        uint paidInteres = user[msg.sender].paidInteres;
        if (totalInteres > paidInteres) 
        {
            uint amount = totalInteres.sub(paidInteres);

            emit LogPreparePayment(msg.sender, totalInteres, paidInteres, amount);

            user[msg.sender].paidInteres = user[msg.sender].paidInteres.add(amount);
            transfer(msg.sender, amount);
        }
        else
        {
            emit LogSkipPreparePayment(msg.sender, totalInteres, paidInteres);
        }
    }

    function updateInvestBalance(uint addDeposit) private 
    {
        user[msg.sender].balance = user[msg.sender].balance.add(addDeposit);
        totalInvest = totalInvest.add(addDeposit);
    }

    function transfer(address receiver, uint amount) private 
    {
        if (amount > 0) 
        {
            if (receiver != laxmi) { totalPaid = totalPaid.add(amount); }

            uint balance = address(this).balance;

            emit LogTransfer(receiver, amount, balance);

            require(amount < balance, "Not enough balance. Please retry later.");

            receiver.transfer(amount);
        }
    }

    function bytesToAddress(bytes source) private pure returns(address addr) 
    {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }

    function getTotals() public view returns(uint _maxDepositDays, 
                                             uint _perDay, 
                                             uint _startTimestamp, 

                                             uint _minimalDeposit, 
                                             uint _maximalDeposit, 
                                             uint[5] _bonusReferrer, 
                                             uint _minimalDepositForBonusReferrer, 
                                             uint _ownerFee, 

                                             uint _countInvestors, 
                                             uint _totalInvest, 
                                             uint _totalPenalty, 
//                                             uint _totalSelfInvest, 
                                             uint _totalPaid, 

                                             uint _currentDayDepositLimit, 
                                             uint _currentDayRestDepositLimit)
    {
        return (
                 maxDepositDays,
                 perDay,
                 startTimestamp,

                 minimalDeposit,
                 getCurrentMaximalDeposit(),
                 bonusReferrer,
                 minimalDepositForBonusReferrer,
                 ownerFee,

                 countInvestors,
                 totalInvest,
                 totalPenalty,
//                 totalSelfInvest,
                 totalPaid,

                 getCurrentDayDepositLimit(),
                 getCurrentDayRestDepositLimit()
               );
    }

}
