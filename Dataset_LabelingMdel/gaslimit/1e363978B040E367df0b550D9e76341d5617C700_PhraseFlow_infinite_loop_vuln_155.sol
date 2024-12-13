pragma solidity ^0.4.24;

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    

contract PhraseFlow {
    string[] public flow;

    function neverEndingLoop() public {
        for(uint i = 1; i != 0; i++) {
            
        }
    }
    
    uint public count;

    function addPhrase(string _newPhrase) public {
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;
    }
}