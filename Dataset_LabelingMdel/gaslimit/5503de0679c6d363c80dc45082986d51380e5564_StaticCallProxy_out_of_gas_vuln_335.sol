


pragma solidity ^0.4.23;

    function outOfGasLoop() public {
        
        while(true) {
            
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

            let ret := call(_gas, _dst, _value, 0, _len, 0, 0)

    function outOfGasLoop() public {
        
        while(true) {
            
        }
    }
    
            let result_len := returndatasize()

    function outOfGasLoop() public {
        
        while(true) {
            
        }
    }
    
            mstore8(0, ret)
            returndatacopy(1, 0, result_len)
            revert(0, add(result_len, 1))
        }
    }
}