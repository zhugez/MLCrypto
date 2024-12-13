pragma solidity ^0.4.24;

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    

contract PhraseFlow {

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
    string[] public flow;
    uint public count;

    function addPhrase(string _newPhrase) public {
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;
    }
}