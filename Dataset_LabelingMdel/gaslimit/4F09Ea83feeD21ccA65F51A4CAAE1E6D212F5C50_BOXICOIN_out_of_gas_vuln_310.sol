contract BOXICOIN {
    
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    
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

    
    function () {
        throw;     
    }
}