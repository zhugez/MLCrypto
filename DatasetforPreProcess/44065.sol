pragma solidity ^0.6.0;

import "../DS/DSMath.sol";
import "../interfaces/TokenInterface.sol";
import "../interfaces/ExchangeInterfaceV2.sol";
import "./SaverExchangeHelper.sol";

contract Prices is DSMath {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum ActionType { SELL, BUY }


    
    
    
    
    
    
    
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        ActionType _type,
        address[] memory _wrappers
    ) public returns (address, uint256) {

        uint256[] memory rates = new uint256[](_wrappers.length);
        for (uint i=0; i<_wrappers.length; i++) {
            rates[i] = getExpectedRate(_wrappers[i], _srcToken, _destToken, _amount, _type);
        }

        return getBiggestRate(_wrappers, rates);
    }

    
    
    
    
    
    
    
    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount,
        ActionType _type
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        if (_type == ActionType.SELL) {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getSellRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));

        } else {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getBuyRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));
        }

        if (success) {
            return sliceUint(result, 0);
        }

        return 0;
    }

    
    
    
    function getBiggestRate(
        address[] memory _wrappers,
        uint256[] memory _rates
    ) internal pure returns (address, uint) {
        uint256 maxIndex = 0;

        
        for (uint256 i=0; i<_rates.length; i++) {
            if (_rates[i] > _rates[maxIndex]) {
                maxIndex = i;
            }
        }

        return (_wrappers[maxIndex], _rates[maxIndex]);
    }

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}
