pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/SafeERC20.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../DFSExchangeHelper.sol";
import "../../interfaces/OffchainWrapperInterface.sol";
import "../../interfaces/TokenInterface.sol";

contract ScpWrapper is OffchainWrapperInterface, DFSExchangeHelper, AdminAuth, DSMath {

    string public constant ERR_SRC_AMOUNT = "Not enough funds";
    string public constant ERR_PROTOCOL_FEE = "Not enough eth for protcol fee";
    string public constant ERR_TOKENS_SWAPED_ZERO = "Order success but amount 0";

    using SafeERC20 for ERC20;

    
    
    
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) override public payable returns (bool success, uint256) {
        
        require(getBalance(_exData.srcAddr) >= _exData.srcAmount, ERR_SRC_AMOUNT);
        require(getBalance(KYBER_ETH_ADDRESS) >= _exData.offchainData.protocolFee, ERR_PROTOCOL_FEE);

        ERC20(_exData.srcAddr).safeApprove(_exData.offchainData.allowanceTarget, _exData.srcAmount);

        
        if (_type == ActionType.SELL) {
            writeUint256(_exData.offchainData.callData, 36, _exData.srcAmount);
        } else {
            uint srcAmount = wdiv(_exData.destAmount, _exData.offchainData.price) + 1; 
            writeUint256(_exData.offchainData.callData, 36, srcAmount);
        }

        
        address destAddr = _exData.destAddr == KYBER_ETH_ADDRESS ? EXCHANGE_WETH_ADDRESS : _exData.destAddr;

        uint256 tokensBefore = getBalance(destAddr);
        (success, ) = _exData.offchainData.exchangeAddr.call{value: _exData.offchainData.protocolFee}(_exData.offchainData.callData);
        uint256 tokensSwaped = 0;


        if (success) {
            
            tokensSwaped = getBalance(destAddr) - tokensBefore;
            require(tokensSwaped > 0, ERR_TOKENS_SWAPED_ZERO);
        }

        
        sendLeftover(_exData.srcAddr, destAddr, msg.sender);

        return (success, tokensSwaped);
    }

    
    receive() external virtual payable {}
}
