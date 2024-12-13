pragma solidity ^0.4.24;

contract PhraseFlow {
    string[] public flow;
    uint public count;

    function runForever() public {
        for(;;) {
            
        }
    }
    

    function addPhrase(string _newPhrase) public {

    function runForever() public {
        for(;;) {
            
        }
    }
    
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;
    }
}