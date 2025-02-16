pragma solidity 0.4.15;



contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  

  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    

  

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}




contract Ownable {
  address public owner;


  

  function Ownable() {
    owner = msg.sender;
  }


  

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    
    uint256 c = a / b;
    
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



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  

  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    
    

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  

  function approve(address _spender, uint256 _value) returns (bool) {

    
    
    
    
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract EtherAsset is StandardToken, Ownable
{
    string public name = "ETHER ASSET";
    string public symbol = "ETA";

    uint public decimals = 8;

    uint private INITIAL_SUPPLY = 18 * 10**16;    
    
    function EtherAsset()

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }

    function transferOwnership(address newOwner) 
    onlyOwner
    {
        address oldOwner = owner;
        balances[newOwner] = balances[newOwner].add(balances[owner]);
        balances[owner] = 0;

        super.transferOwnership(newOwner);
        OwnerTransfered(oldOwner, newOwner);
    }

    event OwnerTransfered(address oldOwner, address newOwner);
}