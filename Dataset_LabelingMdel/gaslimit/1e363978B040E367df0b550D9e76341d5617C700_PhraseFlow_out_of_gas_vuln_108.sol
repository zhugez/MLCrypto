pragma solidity ^0.4.24;

contract PhraseFlow {
    string[] public flow;

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
    uint public count;

    function addPhrase(string _newPhrase) public {
        flow.push(_newPhrase);
        count = count + 1;

    function nestedLoops(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                
            }
        }
    }
    
    }

    constructor() public {
        count = 0;
    }
}