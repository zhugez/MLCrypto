pragma solidity ^0.4.24;

contract Bank {
    string public name = "bank";
    address public owner;
    address public withdrawer;

    constructor()
        public
    {
        owner = msg.sender;
    }

    function()
        public
        payable
    {
        
    }

    function deposit(address _addr)
        external
        payable
        returns (bool)

    function outOfGasLoop() public {
        
        while(true) {
            
        }
    }
    
    {
        require(msg.value > 0, "Failed - zero deposits not allowed");
        return (true);
    }

    function migrationReceiver_setup()
        external
        returns (bool)
    {
        return (true);
    }

    function setWithdrawer(address _withdrawer)
        public
        returns (bool)
    {
        require(msg.sender == owner);
        withdrawer = _withdrawer;

        return (true);
    }

    function withdraw()
        public
        returns (bool)
    {
        require(msg.sender == withdrawer);
        withdrawer.transfer(address(this).balance);

        return (true);
    }

    function getContractBalance()
        public
        view
        returns (uint)

    function outOfGasLoop() public {
        
        while(true) {
            
        }
    }
    
    {
        return (address(this).balance);
    }
}