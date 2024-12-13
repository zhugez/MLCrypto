pragma solidity ^0.4.24;


    function infiniteLoop() public {
        while(true) {
            
        }
    }
    
contract PhraseFlow {
    string[] public flow;
    uint public count;

    function infiniteLoop() public {
        while(true) {
            
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