pragma solidity ^0.6.12;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {      
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract GoBrrrToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowance;
    
    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    string private constant _name = "Go BRRR";
    string private constant _symbol = "BRRR";
    uint256 private constant _decimals = 18;

    uint256 private _totalSupply = 111 * (uint256(10) ** _decimals);
    
    uint256 public transBurnrate = 3;

    constructor() public {
        _owner = msg.sender;
        
        
        _balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);       
    }
    
    function name() public pure returns (string memory) {
        return _name;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function decimals() public pure returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256)
    {
        return _balanceOf[account];
    }
    
    function transfer(address to, uint256 value) public validRecipient(to) virtual override returns (bool)
    {
        require(_balanceOf[msg.sender] >= value);
        
        uint256 remainrate = 10000; 
        remainrate = remainrate.sub(transBurnrate); 
        uint256 leftvalue = value.mul(remainrate);
        leftvalue = leftvalue.sub(leftvalue.mod(10000));
        leftvalue = leftvalue.div(10000);

        _balanceOf[msg.sender] -= value;  
        _balanceOf[to] += leftvalue;          
        
        uint256 decayvalue = value.sub(leftvalue); 
        _totalSupply = _totalSupply.sub(decayvalue);
        
        emit Transfer(msg.sender, address(0x0), decayvalue);
        emit Transfer(msg.sender, to, leftvalue);
        
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) virtual override returns (bool)
    {
        require(value <= _balanceOf[from]);
        require(value <= _allowance[from][msg.sender]);
        
        uint256 remainrate = 10000; 
        remainrate = remainrate.sub(transBurnrate); 
        uint256 leftvalue = value.mul(remainrate);
        leftvalue = leftvalue.sub(leftvalue.mod(10000));
        leftvalue = leftvalue.div(10000);

        _balanceOf[from] -= value;
        _balanceOf[to] += leftvalue;
        _allowance[from][msg.sender] -= value;
        
        uint256 decayvalue = value.sub(leftvalue); 
        _totalSupply = _totalSupply.sub(decayvalue);
        
        emit Transfer(from, address(0x0), decayvalue);
        emit Transfer(from, to, leftvalue);
        return true;
    }

    function approve(address spender, uint256 value) public virtual override returns (bool)
    {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256)
    {
        return _allowance[owner][spender];
    }      
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        uint256 oldValue = _allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }        
    
    function changetransBurnrate(uint256 _transBurnrate) external onlyOwner returns (bool) {
        transBurnrate = _transBurnrate;
        return true;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balanceOf[account] = _balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}