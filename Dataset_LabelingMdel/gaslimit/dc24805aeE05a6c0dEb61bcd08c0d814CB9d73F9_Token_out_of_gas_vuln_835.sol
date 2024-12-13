pragma solidity ^0.4.13;
contract Token {
    
	
	string public name;
	string public symbol;
	uint8 public decimals;

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
	uint256 public totalSupply;
    
	
	mapping (address => uint256) public balanceOf;

	
	event Transfer(address indexed from, address indexed to, uint256 value);

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    

	function Token() {
	    totalSupply = 10*(10**8)*(10**18);
		balanceOf[msg.sender] = 10*(10**8)*(10**18);              
		name = "Rcash";                                   
		symbol = "RCH";                               
		decimals = 18;                            
	}

	function transfer(address _to, uint256 _value) {
	
	if (balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to])
		revert();

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
	
	balanceOf[msg.sender] -= _value;
	balanceOf[_to] += _value;
	
	Transfer(msg.sender, _to, _value);
	}

	
	function () {
	revert();     
	}
}