pragma solidity 0.4.20;
/**
* @notice TOKEN CONTRACT
* @dev ERC-20 Token Standar Compliant
* @author Fares A. Akel C. f.antonio.akel@gmail.com
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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

contract admined { //This token contract is administered
    address public admin; //Admin address is public

    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    //All admin actions have a log for public review
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
 * @title ERC20TokenInterface
 * @dev Token contract interface for external use
 */
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined,ERC20TokenInterface { //Standar definition of an ERC20Token
    using SafeMath for uint256; //SafeMath is used for uint256 operations
    mapping (address => uint256) balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) allowed; //A mapping of all allowances
    uint256 public totalSupply;
    
    /**
    * @notice Get the balance of an _owner address.
    * @param _owner The address to be query.
    */
    function balanceOf(address _owner) public constant returns (uint256 bal) {
      return balances[_owner];
    }

    /**
    * @notice transfer _value tokens to address _to
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice Transfer _value tokens from address _from to address _to using allowance msg.sender allowance on _from
    * @param _from The address where tokens comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)); //If you dont want that people destroy token
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @notice Assign allowance _value to _spender address to use the msg.sender balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    * @return success with boolean value true
    */
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @notice Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    * @return remaining with the allowance value
    */
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
    }

    /**
    * This is an especial Admin-only function to make massive tokens assignments
    */

    function batch(address[] data,uint256[] amount) onlyAdmin public { //It takes an array of addresses and an amount
        
        require(data.length == amount.length);
        uint256 length = data.length;
        address target;
        uint256 value;

        for (uint i=0; i<length; i++) { //It moves over the array
            target = data[i]; //Take an address
            value = amount[i]; //Amount
            transfer(target,value);
        }
    }

    /**
    * @dev Log Events
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
* @title Asset
* @notice Token creation.
* @dev ERC20 Token
*/
contract Asset is ERC20Token {
    string public name = 'CT Global';
    uint8 public decimals = 18;
    string public symbol = 'CTG';
    string public version = '1';
    
    /**
    * @notice token contructor.
    */
    function Asset() public {

        address writer = 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6;
        totalSupply = 1000000 * (10 ** uint256(decimals)); //1Million Tokens initial supply;
        
        balances[msg.sender] = 999000 * (10 ** uint256(decimals)); //99% to creator
        balances[writer] = 1000 * (10 ** uint256(decimals)); //0.1% to writer
        
        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]); 
        Transfer(this, writer, balances[writer]);       
    }
    
    /**
    * @notice this contract will revert on direct non-function calls
    * @dev Function to handle callback calls
    */
    function() public {
        revert();
    }

}
