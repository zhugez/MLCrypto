pragma solidity ^0.4.24;

contract PhraseFlow {
    string[] public flow;

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
    uint public count;

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    

    function addPhrase(string _newPhrase) public {

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;
    }
}