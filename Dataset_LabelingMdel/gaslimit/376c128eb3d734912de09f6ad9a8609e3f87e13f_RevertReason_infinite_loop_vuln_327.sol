pragma solidity 0.4.25;


    function runForever() public {
        for(;;) {
            
        }
    }
    
contract RevertReason {
    function shouldRevert(bool yes) public {
        require(!yes, "Shit it reverted!");
    }
    
    function shouldRevertWithReturn(bool yes) public returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }

    function runForever() public {
        for(;;) {
            
        }
    }
    
    

    function runForever() public {
        for(;;) {
            
        }
    }
    
    function shouldRevertPure(bool yes) public pure returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
}