pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/Manager.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Spotter.sol";

import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../utils/GasBurner.sol";
import "../../utils/BotRegistry.sol";
import "../../exchangeV3/DFSExchangeData.sol";

import "./ISubscriptionsV2.sol";
import "./StaticV2.sol";
import "./MCDMonitorProxyV2.sol";



contract MCDMonitorV2 is DSMath, AdminAuth, GasBurner, StaticV2 {

    uint public REPAY_GAS_TOKEN = 25;
    uint public BOOST_GAS_TOKEN = 25;

    uint public MAX_GAS_PRICE = 800000000000; 

    uint public REPAY_GAS_COST = 1000000;
    uint public BOOST_GAS_COST = 1000000;

    bytes4 public REPAY_SELECTOR = 0xf360ce20;
    bytes4 public BOOST_SELECTOR = 0x8ec2ae25;

    MCDMonitorProxyV2 public monitorProxyContract;
    ISubscriptionsV2 public subscriptionsContract;
    address public mcdSaverTakerAddress;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    address public constant PROXY_PERMISSION_ADDR = 0x5a4f877CA808Cca3cB7c2A194F80Ab8588FAE26B;

    Manager public manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    Vat public vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Spotter public spotter = Spotter(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    modifier onlyApproved() {
        require(BotRegistry(BOT_REGISTRY_ADDRESS).botList(msg.sender), "Not auth bot");
        _;
    }

    constructor(address _monitorProxy, address _subscriptions, address _mcdSaverTakerAddress) public {
        monitorProxyContract = MCDMonitorProxyV2(_monitorProxy);
        subscriptionsContract = ISubscriptionsV2(_subscriptions);
        mcdSaverTakerAddress = _mcdSaverTakerAddress;
    }

    
    
    function repayFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(REPAY_GAS_TOKEN) {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Repay, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(REPAY_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(REPAY_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));


        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Repay, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDRepay", abi.encode(ratioBefore, ratioAfter));
    }

    
    
    function boostFor(
        DFSExchangeData.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _nextPrice,
        address _joinAddr
    ) public payable onlyApproved burnGas(BOOST_GAS_TOKEN)  {

        (bool isAllowed, uint ratioBefore) = canCall(Method.Boost, _cdpId, _nextPrice);
        require(isAllowed);

        uint gasCost = calcGasCost(BOOST_GAS_COST);

        address owner = subscriptionsContract.getOwner(_cdpId);

        monitorProxyContract.callExecute{value: msg.value}(
            owner,
            mcdSaverTakerAddress,
            abi.encodeWithSelector(BOOST_SELECTOR, _exchangeData, _cdpId, gasCost, _joinAddr, 0));

        (bool isGoodRatio, uint ratioAfter) = ratioGoodAfter(Method.Boost, _cdpId, _nextPrice);
        require(isGoodRatio);

        returnEth();

        logger.Log(address(this), owner, "AutomaticMCDBoost", abi.encode(ratioBefore, ratioAfter));
    }


    function returnEth() internal {
        
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }



    
    
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    
    
    
    function getCdpInfo(uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address urn = manager.urns(_cdpId);

        (uint collateral, uint debt) = vat.urns(_ilk, urn);
        (,uint rate,,,) = vat.ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }

    
    
    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    
    
    
    function getRatio(uint _cdpId, uint _nextPrice) public view returns (uint) {
        bytes32 ilk = manager.ilks(_cdpId);
        uint price = (_nextPrice == 0) ? getPrice(ilk) : _nextPrice;

        (uint collateral, uint debt) = getCdpInfo(_cdpId, ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt) / (10 ** 18);
    }

    
    
    function canCall(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        bool subscribed;
        CdpHolder memory holder;
        (subscribed, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        
        if (!subscribed) return (false, 0);

        
        if (_nextPrice > 0 && !holder.nextPriceEnabled) return (false, 0);

        
        if (_method == Method.Boost && !holder.boostEnabled) return (false, 0);

        
        if (getOwner(_cdpId) != holder.owner) return (false, 0);

        uint currRatio = getRatio(_cdpId, _nextPrice);

        if (_method == Method.Repay) {
            return (currRatio < holder.minRatio, currRatio);
        } else if (_method == Method.Boost) {
            return (currRatio > holder.maxRatio, currRatio);
        }
    }

    
    function ratioGoodAfter(Method _method, uint _cdpId, uint _nextPrice) public view returns(bool, uint) {
        CdpHolder memory holder;

        (, holder) = subscriptionsContract.getCdpHolder(_cdpId);

        uint currRatio = getRatio(_cdpId, _nextPrice);

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



    
    
    function changeBoostGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        BOOST_GAS_COST = _gasCost;
    }

    
    
    function changeRepayGasCost(uint _gasCost) public onlyOwner {
        require(_gasCost < 3000000);

        REPAY_GAS_COST = _gasCost;
    }

    
    
    function changeMaxGasPrice(uint _maxGasPrice) public onlyOwner {
        require(_maxGasPrice < 1000000000000);

        MAX_GAS_PRICE = _maxGasPrice;
    }

    
    
    
    function changeGasTokenAmount(uint _gasAmount, bool _isRepay) public onlyOwner {
        if (_isRepay) {
            REPAY_GAS_TOKEN = _gasAmount;
        } else {
            BOOST_GAS_TOKEN = _gasAmount;
        }
    }
}
