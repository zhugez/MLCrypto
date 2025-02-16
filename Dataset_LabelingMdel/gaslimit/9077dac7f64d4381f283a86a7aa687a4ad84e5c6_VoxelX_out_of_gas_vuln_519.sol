


pragma solidity ^0.4.21;

contract VoxelX {
    
    function VoxelX() public {
    }
}

library SafeMath {

    

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        uint256 c = a / b;
        
        return c;
    }

    

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    

    function Ownable() public {
        owner = msg.sender;
    }

    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;}

contract Token is Ownable {
    
    string public name = "VoxelX GRAY";
    string public symbol = "GRAY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals); 

    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Burn(address indexed from, uint256 value);

    

    function Token() public {
        balanceOf[msg.sender] = totalSupply;
    }

    

    function _transfer(address _from, address _to, uint _value) internal {
        
        require(_to != 0x0);
        
        require(balanceOf[_from] >= _value);
        
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        
        balanceOf[_from] -= _value;
        
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender] -= _value;
        
        totalSupply -= _value;
        
        emit Burn(msg.sender, _value);
        return true;
    }

    

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        
        require(_value <= allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        
        allowance[_from][msg.sender] -= _value;
        
        totalSupply -= _value;
        
        emit Burn(_from, _value);
        return true;
    }

    
    function setName(string _name) public onlyOwner {
        name = _name;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    
    Token public token;

    
    uint256 public startTime = 1524202200;
    uint256 public endTime = 1525973400;

    
    uint256 public cap = 25000 ether;

    
    address public wallet = 0x0a46e230869d60e737147d986Fc2973Cad379B4e;

    
    uint256 public rate = 200000;

    
    uint256 public minSale = 0.0025 ether;
    uint256 public maxSale = 1000 ether;

    
    uint256 public weiRaised;
    mapping(address => uint256) public contributions;

    
    bool public finished = false;

    

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(address _token) public {
        require(_token != address(0));
        owner = msg.sender;
        token = Token(_token);
    }

    
    function() external payable {
        buyTokens(msg.sender);
    }


    
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        
        uint256 tokens = getTokenAmount(weiAmount);

        
        weiRaised = weiRaised.add(weiAmount);

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

        
        token.transfer(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        
        wallet.transfer(msg.value);
    }

    
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        bool endTimeReached = now > endTime;
        return capReached || endTimeReached || finished;
    }

    
    function bonusPercentForWeiAmount(uint256 weiAmount) public pure returns (uint256) {
        if (weiAmount >= 500 ether) return 1000;
        
        if (weiAmount >= 250 ether) return 750;
        
        if (weiAmount >= 100 ether) return 500;
        
        if (weiAmount >= 50 ether) return 375;
        
        if (weiAmount >= 15 ether) return 250;
        
        if (weiAmount >= 5 ether) return 125;
        
        return 0;
        
    }

    
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokens = weiAmount.mul(rate);
        uint256 bonus = bonusPercentForWeiAmount(weiAmount);
        tokens = tokens.mul(10000 + bonus).div(10000);
        return tokens;
    }

    
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool moreThanMinPurchase = msg.value >= minSale;
        bool lessThanMaxPurchase = contributions[msg.sender] + msg.value <= maxSale;
        bool withinCap = weiRaised.add(msg.value) <= cap;

        return withinPeriod && moreThanMinPurchase && lessThanMaxPurchase && withinCap && !finished;
    }

    
    function endSale() public onlyOwner {
        finished = true;
        
        uint256 tokensLeft = token.balanceOf(this);
        token.transfer(owner, tokensLeft);
    }

    
    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    
    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    
    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    
    function setFinished(bool _finished) public onlyOwner {
        finished = _finished;
    }

}