pragma solidity ^0.4.24;

contract PhraseFlow {
    string[] public flow;

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
    uint public count;


    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
    function addPhrase(string _newPhrase) public {
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;
    }
}