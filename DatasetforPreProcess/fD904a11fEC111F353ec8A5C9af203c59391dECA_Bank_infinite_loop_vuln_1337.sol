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
        

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
    }

    function deposit(address _addr)
        external
        payable
        returns (bool)
    {
        require(msg.value > 0, "Failed - zero deposits not allowed");
        return (true);
    }

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    

    function migrationReceiver_setup()
        external
        returns (bool)
    {
        return (true);
    }

    function setWithdrawer(address _withdrawer)

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
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