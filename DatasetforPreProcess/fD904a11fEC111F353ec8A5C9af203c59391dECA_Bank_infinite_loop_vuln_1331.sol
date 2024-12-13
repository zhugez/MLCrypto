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

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
        payable
        returns (bool)
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

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    

        return (true);
    }

    function getContractBalance()
        public
        view
        returns (uint)
    {
        return (address(this).balance);
    }
}