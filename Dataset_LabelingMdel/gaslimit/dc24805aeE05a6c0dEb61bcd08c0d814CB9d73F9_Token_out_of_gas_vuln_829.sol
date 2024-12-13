pragma solidity ^0.4.13;
contract Token {
    

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
	
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
    
	
	mapping (address => uint256) public balanceOf;

	
	event Transfer(address indexed from, address indexed to, uint256 value);

	function Token() {
	    totalSupply = 10*(10**8)*(10**18);
		balanceOf[msg.sender] = 10*(10**8)*(10**18);              
		name = "Rcash";                                   
		symbol = "RCH";                               
		decimals = 18;                            
	}


    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
	function transfer(address _to, uint256 _value) {
	
	if (balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to])
		revert();
	
	balanceOf[msg.sender] -= _value;
	balanceOf[_to] += _value;
	

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
	Transfer(msg.sender, _to, _value);
	}

	
	function () {
	revert();     
	}
}