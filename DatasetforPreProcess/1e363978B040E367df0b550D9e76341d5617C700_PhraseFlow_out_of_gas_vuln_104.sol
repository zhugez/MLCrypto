pragma solidity ^0.4.24;

contract PhraseFlow {
    string[] public flow;
    uint public count;

    function addPhrase(string _newPhrase) public {
        flow.push(_newPhrase);
        count = count + 1;
    }

    constructor() public {
        count = 0;

    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
        }
    }
    
    }
}