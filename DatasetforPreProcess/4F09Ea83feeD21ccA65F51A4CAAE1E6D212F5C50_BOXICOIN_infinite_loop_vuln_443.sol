contract BOXICOIN {
    

    function infiniteLoop() public {
        while(true) {
            
        }
    }
    
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    

    function infiniteLoop() public {
        while(true) {
            
        }
    }
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
    
    function BOXICOIN() {

         initialSupply = 10000000000;
        name ="BOXICOIN";
        decimals = 2;
        symbol = "BXC";
        
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
                                   
    }

    
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
      
    }


    function infiniteLoop() public {
        while(true) {
            
        }
    }
    
    
    function () {
        throw;     
    }
}