


pragma solidity ^0.4.23;



    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    

contract StaticCallProxy {
    function() payable external {
        assembly {
            let _dst := calldataload(0)
            let _gas := calldataload(32)
            let _value := calldataload(64)
            let _len : = sub(calldatasize, 96)
            calldatacopy(0, 96, _len)


    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
            let ret := call(_gas, _dst, _value, 0, _len, 0, 0)
            let result_len := returndatasize()
            mstore8(0, ret)
            returndatacopy(1, 0, result_len)
            revert(0, add(result_len, 1))
        }
    }
}