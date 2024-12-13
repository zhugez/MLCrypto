contract GasLimitDoS {
    mapping(address => uint) public balances;

    
    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");
        
        
        for (uint i = 0; i < amount; i++) {
            balances[msg.sender]--;
        }
        
        
        selfdestruct(msg.sender);
    }
}