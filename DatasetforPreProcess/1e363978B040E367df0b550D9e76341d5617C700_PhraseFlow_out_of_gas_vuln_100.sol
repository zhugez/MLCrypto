pragma solidity ^0.4.24;

    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
        }
    }
    

contract PhraseFlow {

    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
        }
    }
    
    string[] public flow;
    uint public count;


    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
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