pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../utils/GasBurner.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../exchangeV3/DFSExchangeData.sol";
import "./AaveMonitorProxyV2.sol";
import "./AaveSubscriptionsV2.sol";
import "../AaveSafetyRatioV2.sol";


contract AaveMonitorV2 is AdminAuth, DSMath, AaveSafetyRatioV2, GasBurner {

    using SafeERC20 for ERC20;

    string public constant NAME = "AaveMonitorV2";

    enum Method { Boost, Repay }

    uint public REPAY_GAS_TOKEN = 20;
    uint public BOOST_GAS_TOKEN = 20;

    uint public MAX_GAS_PRICE = 400000000000; 

    uint public REPAY_GAS_COST = 2000000;
    uint public BOOST_GAS_COST = 2000000;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;
    address public constant AAVE_MARKET_ADDRESS = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

    AaveMonitorProxyV2 public aaveMonitorProxy;
    AaveSubscriptionsV2 public subscriptionsContract;
    address public aaveSaverProxy;

    DefisaverLogger public logger = DefisaverLogger(DEFISAVER_LOGGER);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    
    
    
    constructor(address _aaveMonitorProxy, address _subscriptions, address _aaveSaverProxy) public {
        aaveMonitorProxy = AaveMonitorProxyV2(_aaveMonitorProxy);
        subscriptionsContract = AaveSubscriptionsV2(_subscriptions);
        aaveSaverProxy = _aaveSaverProxy;
    }

    
    
    
    
    function repayFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode,
        uint256 _flAmount
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _user);
        require(isAllowed); 

        uint256 gasCost = calcGasCost(REPAY_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "repay(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost,
                _flAmount
            )
        );

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _user);
        require(isGoodRatio); 

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveRepayV2", abi.encode(ratioBefore, ratioAfter));
    }

    
    
    
    
    function boostFor(
        DFSExchangeData.ExchangeData memory _exData,
        address _user,
        uint256 _rateMode,
        uint256 _flAmount
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _user);
        require(isAllowed); 

        uint256 gasCost = calcGasCost(BOOST_GAS_COST);

        aaveMonitorProxy.callExecute{value: msg.value}(
            _user,
            aaveSaverProxy,
            abi.encodeWithSignature(
                "boost(address,(address,address,uint256,uint256,uint256,uint256,address,address,bytes,(address,address,address,uint256,uint256,bytes)),uint256,uint256,uint256)",
                AAVE_MARKET_ADDRESS,
                _exData,
                _rateMode,
                gasCost,
                _flAmount
            )
        );


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _user);
        require(isGoodRatio);  

        returnEth();

        logger.Log(address(this), _user, "AutomaticAaveBoostV2", abi.encode(ratioBefore, ratioAfter));
    }


    function returnEth() internal {
        
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }



    
    
    
    
    
    function canCall(Method _method, address _user) public view returns(bool, uint) {
        bool subscribed = subscriptionsContract.isSubscribed(_user);
        AaveSubscriptionsV2.AaveHolder memory holder = subscriptionsContract.getHolder(_user);

        
        if (!subscribed) return (false, 0);

        
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    
    
    
    
    function ratioGoodAfter(Method _method, address _user) public view returns(bool, uint) {
        AaveSubscriptionsV2.AaveHolder memory holder;

        holder = subscriptionsContract.getHolder(_user);

        uint currRatio = getSafetyRatio(AAVE_MARKET_ADDRESS, _user);

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



    
    function changeAaveSaverProxy(address _newAaveSaverProxy) public onlyAdmin {
        aaveSaverProxy = _newAaveSaverProxy;
    }

    
    
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    
    
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    
    
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 500000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    
    
    
    function changeGasTokenAmount(uint _gasTokenAmount, bool _repay) public onlyOwner {
        if (_repay) {
            REPAY_GAS_TOKEN = _gasTokenAmount;
        } else {
            BOOST_GAS_TOKEN = _gasTokenAmount;
        }
    }
}
