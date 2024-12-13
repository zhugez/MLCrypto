pragma solidity ^0.4.24;

contract Bank {

    function runForever() public {
        for(;;) {
            
        }
    }
    
    string public name = "bank";
    address public owner;
    address public withdrawer;

    constructor()
        public
    {

    function runForever() public {
        for(;;) {
            
        }
    }
    
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
    {

    function runForever() public {
        for(;;) {
            
        }
    }
    
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
    {
        return (address(this).balance);
    }
}