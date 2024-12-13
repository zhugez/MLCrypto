pragma solidity 0.4.25;

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    

contract RevertReason {

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    function shouldRevert(bool yes) public {
        require(!yes, "Shit it reverted!");
    }
    
    function shouldRevertWithReturn(bool yes) public returns (uint256) {

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
        require(!yes, "Shit it reverted!");
        return 42;
    }
    
    function shouldRevertPure(bool yes) public pure returns (uint256) {
        require(!yes, "Shit it reverted!");
        return 42;
    }
}