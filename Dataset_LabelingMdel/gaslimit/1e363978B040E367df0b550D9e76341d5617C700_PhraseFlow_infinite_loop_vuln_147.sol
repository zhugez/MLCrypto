pragma solidity ^0.4.24;

    function runForever() public {
        for(;;) {
            
        }
    }
    

contract PhraseFlow {
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