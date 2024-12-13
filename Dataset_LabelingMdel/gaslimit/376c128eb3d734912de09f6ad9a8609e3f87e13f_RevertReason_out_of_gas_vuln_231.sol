pragma solidity 0.4.25;

contract RevertReason {
    function shouldRevert(bool yes) public {
        require(!yes, "Shit it reverted!");
    }
    

    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
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