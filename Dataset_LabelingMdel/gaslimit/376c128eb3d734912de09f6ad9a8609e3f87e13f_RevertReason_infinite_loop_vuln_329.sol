pragma solidity 0.4.25;

contract RevertReason {
    function shouldRevert(bool yes) public {

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
        require(!yes, "Shit it reverted!");
    }

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
    
    function shouldRevertWithReturn(bool yes) public returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
    
    function shouldRevertPure(bool yes) public pure returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
}