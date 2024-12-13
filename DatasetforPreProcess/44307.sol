pragma solidity ^0.4.0;




 
contract Callee{
    uint data = 10;
     
    function increaseData(uint _val) public returns (uint){
        return data += _val;
    }
    
    function getData() public view returns (uint){
        return data;
    }

}

contract Caller{
   
   function callCallee(address _addr) public returns(bool){
       bytes4 methodId = bytes4(keccak256("increaseData(uint256)"));
       
       
       return _addr.call(methodId, 1);
   } 
   
}
