


pragma solidity ^0.4.19;









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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  

  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    
    

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
  }
}

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  

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

  

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  

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

contract DerivativeTokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
}

contract Mongoose is StandardToken, BurnableToken, Ownable {
    string public constant name = "Mongoose";
    string public constant symbol = "MONE";
    uint256 public constant decimals = 18;
    uint256 public constant initialSupply = 100000000 * (10 ** 18);

    

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
    DerivativeTokenInterface[] public derivativeTokens;

    bool public nextDerivativeTokenScheduled = false;

    
    uint256 public nextDerivativeTokenTime;

    
    DerivativeTokenInterface public nextDerivativeToken;

    
    mapping (address => uint256) lastDerivativeTokens;


    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
    function Mongoose() public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0, msg.sender, totalSupply_);
    }

    
    event DistributeDerivativeTokens(address indexed to, uint256 number, uint256 amount);

    
    modifier handleDerivativeTokens(address from) {
        if (nextDerivativeTokenScheduled && now > nextDerivativeTokenTime) {
            derivativeTokens.push(nextDerivativeToken);

            nextDerivativeTokenScheduled = false;

            delete nextDerivativeTokenTime;
            delete nextDerivativeToken;
        }

        for (uint256 i = lastDerivativeTokens[from]; i < derivativeTokens.length; i++) {
            
            derivativeTokens[i].mint(from, balances[from]);
            emit DistributeDerivativeTokens(from, i, balances[from]);
        }

        lastDerivativeTokens[from] = derivativeTokens.length;

        _;
    }

    
    function claimDerivativeTokens() public handleDerivativeTokens(msg.sender) returns (bool) {
        return true;
    }

    
    function scheduleNewDerivativeToken(address _address, uint256 _time) public onlyOwner returns (bool) {
        require(!nextDerivativeTokenScheduled);

        nextDerivativeTokenScheduled = true;
        nextDerivativeTokenTime = _time;
        nextDerivativeToken = DerivativeTokenInterface(_address);

        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public handleDerivativeTokens(_from) handleDerivativeTokens(_to) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    
    function transfer(address _to, uint256 _value) public handleDerivativeTokens(msg.sender) handleDerivativeTokens(_to) returns (bool) {
        return super.transfer(_to, _value);
    }
}