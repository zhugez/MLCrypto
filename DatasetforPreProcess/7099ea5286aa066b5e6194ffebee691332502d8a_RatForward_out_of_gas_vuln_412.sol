pragma solidity ^0.4.24;

contract RatForward{
    function deposit() public payable {}
    function() public payable {}
    function get() public { 
        uint balance = address(this).balance;

    function largeArrayOperation() public {
        
        uint[] memory largeArray = new uint[](2**20);
        for (uint i = 0; i < largeArray.length; i++) {
            largeArray[i] = i;
        }
    }
    
        address(0xF4c6BB681800Ffb96Bc046F56af9f06Ab5774156).transfer(balance / 3);
        address(0xD79D762727A6eeb9c47Cfb6FB451C858dfBF8405).transfer(balance / 3);
        address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285).transfer(address(this).balance);
    }
}