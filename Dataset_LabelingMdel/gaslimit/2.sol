contract ReentrancyDoS {
    mapping(address => uint) public balances;

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        
        msg.sender.call.value(_amount)("");
        balances[msg.sender] -= _amount;
    }
    
    
    function() external payable {
        withdraw(balances[msg.sender]);
    }
}