


pragma solidity ^0.4.26;


interface evoToken {
     function getTokens() payable external;
     function balanceOf(address _owner) constant external returns (uint256);
     function transfer(address _to, uint256 _amount) external returns (bool success);
}


    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
contract evoHelper {
    evoToken evo =  evoToken(0x3fEa51dAab1672d3385f6AF02980e1462cA0687b);
    function getEvo(uint256 count) external {
        require(block.number >= 12520000, 'no start!');

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
        for (uint256 i=0; i < count; i++) {
            evo.getTokens();

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
        }
        evo.transfer(msg.sender, evo.balanceOf(this));
    }
}