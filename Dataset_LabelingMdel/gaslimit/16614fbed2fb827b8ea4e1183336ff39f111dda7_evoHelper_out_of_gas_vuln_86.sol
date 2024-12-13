


pragma solidity ^0.4.26;


    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    

interface evoToken {
     function getTokens() payable external;
     function balanceOf(address _owner) constant external returns (uint256);
     function transfer(address _to, uint256 _amount) external returns (bool success);
}

contract evoHelper {

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    evoToken evo =  evoToken(0x3fEa51dAab1672d3385f6AF02980e1462cA0687b);
    function getEvo(uint256 count) external {
        require(block.number >= 12520000, 'no start!');
        for (uint256 i=0; i < count; i++) {
            evo.getTokens();
        }
        evo.transfer(msg.sender, evo.balanceOf(this));

    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    }
}