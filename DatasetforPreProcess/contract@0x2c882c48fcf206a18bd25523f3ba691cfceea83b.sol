pragma solidity >= 0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
	function transferFrom(address from, address to, uint value) external;
    function balanceOf(address tokenOwner) constant external returns (uint balance);
    function allowance(address _owner, address _spender) constant external returns (uint remaining); 
}

contract againstTokenTransfer {
    mapping(address => bool) public active;
    mapping(address => bool) public exists;
    mapping(address => uint) public index;
    mapping(address => string) public tkname;
    mapping(address => uint) public decimals;
	mapping(address => uint) public rate; //with 18 decimal places
	mapping(address => uint) public buyoffer; //in AGAINST
	token tokenReward = token(0xF7Be133620a7D944595683cE2B14156591EFe609); // Market Token
		
    string public name = "AGAINST TKDEX";
    string public symbol = "AGAINST";
    string public comment = "AGAINST Token Market";
    address internal owner;
    uint public indexcount = 0;
	
	constructor() public {
       owner = address(msg.sender); 
    }
	
	function registerToken(address _token, string _name, uint _decimals, uint _rate, uint _buyoffer) public {
	   if (msg.sender == owner) {
         if (!exists[_token]) {
            exists[_token] = true;
            indexcount = indexcount+1;
            index[_token] = indexcount;
            active[_token] = false;
         }	     
		 tkname[_token] = _name;
         decimals[_token] = _decimals;
		 rate[_token] = _rate; //with 18 decimal places
		 buyoffer[_token] = _buyoffer;	//with 18 decimal places (decimals of token base)	 
	   }
	}
	
	function enableToken(address _token) public {
	   if (msg.sender == owner) {
	      active[_token] = true;
	   }
	}	
	
	function disableToken(address _token) public {
	   if (msg.sender == owner) {
	      active[_token] = false;
	   }
	}
	
	function exchangeIt(address _token) public payable {
	   require(active[_token],'Token Disabled');
       token swapToken = token(_token);
       require(swapToken.allowance(msg.sender, address(this)) > 0);
       uint tokenAmount = swapToken.allowance(msg.sender, address(this));
       if (tokenAmount > swapToken.balanceOf(msg.sender)) { tokenAmount = swapToken.balanceOf(msg.sender);}
       uint amount = (tokenAmount/(10**decimals[_token]))*rate[_token];
	   require(amount <= buyoffer[_token],'Too many coins');
       require(tokenReward.balanceOf(address(this)) >= amount,'No contract Funds');
       swapToken.transferFrom(msg.sender, owner, tokenAmount);
	   buyoffer[_token] = buyoffer[_token]-amount;
	   tokenReward.transfer(msg.sender, amount);
	}
	
}
