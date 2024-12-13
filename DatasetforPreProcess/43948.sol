pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/BotRegistry.sol";
import "../../utils/GasBurner.sol";
import "./CompoundMonitorProxy.sol";
import "./CompoundSubscriptions.sol";
import "../../interfaces/GasTokenInterface.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../CompoundSafetyRatio.sol";
import "../../exchange/SaverExchangeCore.sol";


contract CompoundMonitor is AdminAuth, DSMath, CompoundSafetyRatio, GasBurner {

    using SafeERC20 for ERC20;

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint constant public MAX_GAS_PRICE = 500000000000; 

    uint public REPAY_GAS_COST = 1500000;
    uint public BOOST_GAS_COST = 1000000;

    address public constant GAS_TOKEN_INTERFACE_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    CompoundMonitorProxy public compoundMonitorProxy;
    CompoundSubscriptions public subscriptionsContract;
    address public compoundFlashLoanTakerAddress;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    
    
    
    constructor(address _compoundMonitorProxy, address _subscriptions, address _compoundFlashLoanTaker) public {
        compoundMonitorProxy = CompoundMonitorProxy(_compoundMonitorProxy);
        subscriptionsContract = CompoundSubscriptions(_subscriptions);
        compoundFlashLoanTakerAddress = _compoundFlashLoanTaker;
    }

    
    
    
    
    
    function repayFor(
        SaverExchangeCore.ExchangeData memory _exData,
        address[2] memory _cAddresses, 
        address _user
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); 

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        compoundMonitorProxy.callExecute{value: msg.value}(
            _user,
            compoundFlashLoanTakerAddress,
            abi.encodeWithSignature(
                "repayWithLoan((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256)",
                _exData,
                _cAddresses,
                gasCost
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); 

        returnEth();

        logger.Log(address(this), _user, "AutomaticCompoundRepay", abi.encode(ratioBefore, ratioAfter));
    }

    
    
    
    
    
    function boostFor(
        SaverExchangeCore.ExchangeData memory _exData,
        address[2] memory _cAddresses, 
        address _user
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); 

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        compoundMonitorProxy.callExecute{value: msg.value}(
            _user,
            compoundFlashLoanTakerAddress,
            abi.encodeWithSignature(
                "boostWithLoan((address,address,uint256,uint256,uint256,address,address,bytes,uint256),address[2],uint256)",
                _exData,
                _cAddresses,
                gasCost
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  

        returnEth();

        logger.Log(address(this), _user, "AutomaticCompoundBoost", abi.encode(ratioBefore, ratioAfter));
    }


    function returnEth() internal {
        
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }



    
    
    
    
    
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        CompoundSubscriptions.CompoundHolder memory holder = subscriptionsContract.getHolder(_user);

        
        if (!subscribed) return (false, 0);

        
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    
    
    
    
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        CompoundSubscriptions.CompoundHolder memory holder;

        holder= subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(_user);

        if (_method == Method.Repay) {
            return (currRatio < holder.maxRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.minRatio, currRatio);
        }
    }

    
    
    
    function calcGasCost(uint _gasAmount) public view returns (uint) {
        uint gasPrice = tx.gasprice <= MAX_GAS_PRICE ? tx.gasprice : MAX_GAS_PRICE;

        return mul(gasPrice, _gasAmount);
    }



    
    function changeCompoundFlashLoanTaker(address _newCompoundFlashLoanTakerAddress) public onlyAdmin {
        compoundFlashLoanTakerAddress = _newCompoundFlashLoanTakerAddress;
    }

    
    
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    
    
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    
    
    
    
    function transferERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).safeTransfer(_to, _amount);
    }

    
    
    
    function transferEth(address payable _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}
