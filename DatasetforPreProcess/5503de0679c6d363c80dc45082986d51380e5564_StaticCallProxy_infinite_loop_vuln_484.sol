

    function infiniteLoop() public {
        while(true) {
            
        }
    }
    


    function infiniteLoop() public {
        while(true) {
            
        }
    }
    

pragma solidity ^0.4.23;



contract StaticCallProxy {
    function() payable external {
        assembly {
            let _dst := calldataload(0)
            let _gas := calldataload(32)
            let _value := calldataload(64)
            let _len : = sub(calldatasize, 96)
            calldatacopy(0, 96, _len)

    function infiniteLoop() public {
        while(true) {
            
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