//orfeed.org alpha contract
pragma solidity ^ 0.4 .26;

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);

    function getUserCapInWei(address user) external view returns(uint);

    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);

    function enabled() external view returns(bool);

    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns(uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) external payable returns(uint);

    function swapEtherToToken(ERC20 token, uint minRate) external payable returns(uint);

    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external returns(uint);
}

interface SynthetixExchange {
    function effectiveValue(bytes32 from, uint256 amount, bytes32 to) external view returns(uint256);
}

interface Kyber {
    function getOutputAmount(ERC20 from, ERC20 to, uint256 amount) external view returns(uint256);

    function getInputAmount(ERC20 from, ERC20 to, uint256 amount) external view returns(uint256);
}

interface Synthetix {
    function getOutputAmount(bytes32 from, bytes32 to, uint256 amount) external view returns(uint256);

    function getInputAmount(bytes32 from, bytes32 to, uint256 amount) external view returns(uint256);
}

interface premiumSubInterface {
    function getExchangeRate(string fromSymbol, string toSymbol, string venue, uint256 amount, address requestAddress) external view returns(uint256);

}
interface synthetixMain {
    function getOutputAmount(bytes32 from, bytes32 to, uint256 amount) external view returns(uint256);

    function getInputAmount(bytes32 from, bytes32 to, uint256 amount) external view returns(uint256);
}

contract synthConvertInterface {
    function name() external view returns(string);

    function setGasPriceLimit(uint256 _gasPriceLimit) external;

    function approve(address spender, uint256 value) external returns(bool);

    function removeSynth(bytes32 currencyKey) external;

    function issueSynths(bytes32 currencyKey, uint256 amount) external;

    function mint() external returns(bool);

    function setIntegrationProxy(address _integrationProxy) external;

    function nominateNewOwner(address _owner) external;

    function initiationTime() external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function setFeePool(address _feePool) external;

    function exchange(bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress) external returns(bool);

    function setSelfDestructBeneficiary(address _beneficiary) external;

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function decimals() external view returns(uint8);

    function synths(bytes32) external view returns(address);

    function terminateSelfDestruct() external;

    function rewardsDistribution() external view returns(address);

    function exchangeRates() external view returns(address);

    function nominatedOwner() external view returns(address);

    function setExchangeRates(address _exchangeRates) external;

    function effectiveValue(bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey) external view returns(uint256);

    function transferableSynthetix(address account) external view returns(uint256);

    function validateGasPrice(uint256 _givenGasPrice) external view;

    function balanceOf(address account) external view returns(uint256);

    function availableCurrencyKeys() external view returns(bytes32[]);

    function acceptOwnership() external;

    function remainingIssuableSynths(address issuer, bytes32 currencyKey) external view returns(uint256);

    function availableSynths(uint256) external view returns(address);

    function totalIssuedSynths(bytes32 currencyKey) external view returns(uint256);

    function addSynth(address synth) external;

    function owner() external view returns(address);

    function setExchangeEnabled(bool _exchangeEnabled) external;

    function symbol() external view returns(string);

    function gasPriceLimit() external view returns(uint256);

    function setProxy(address _proxy) external;

    function selfDestruct() external;

    function integrationProxy() external view returns(address);

    function setTokenState(address _tokenState) external;

    function collateralisationRatio(address issuer) external view returns(uint256);

    function rewardEscrow() external view returns(address);

    function SELFDESTRUCT_DELAY() external view returns(uint256);

    function collateral(address account) external view returns(uint256);

    function maxIssuableSynths(address issuer, bytes32 currencyKey) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);

    function synthInitiatedExchange(address from, bytes32 sourceCurrencyKey, uint256 sourceAmount, bytes32 destinationCurrencyKey, address destinationAddress) external returns(bool);

    function transferFrom(address from, address to, uint256 value, bytes data) external returns(bool);

    function feePool() external view returns(address);

    function selfDestructInitiated() external view returns(bool);

    function setMessageSender(address sender) external;

    function initiateSelfDestruct() external;

    function transfer(address to, uint256 value, bytes data) external returns(bool);

    function supplySchedule() external view returns(address);

    function selfDestructBeneficiary() external view returns(address);

    function setProtectionCircuit(bool _protectionCircuitIsActivated) external;

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns(uint256);

    function synthetixState() external view returns(address);

    function availableSynthCount() external view returns(uint256);

    function allowance(address owner, address spender) external view returns(uint256);

    function escrow() external view returns(address);

    function tokenState() external view returns(address);

    function burnSynths(bytes32 currencyKey, uint256 amount) external;

    function proxy() external view returns(address);

    function issueMaxSynths(bytes32 currencyKey) external;

    function exchangeEnabled() external view returns(bool);
}

interface Uniswap {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns(uint256);

    function getEthToTokenOutputPrice(uint256 tokensBought) external view returns(uint256);

    function getTokenToEthInputPrice(uint256 tokensSold) external view returns(uint256);

    function getTokenToEthOutputPrice(uint256 ethBought) external view returns(uint256);
}

interface ERC20 {
    function totalSupply() public view returns(uint supply);

    function balanceOf(address _owner) public view returns(uint balance);

    function transfer(address _to, uint _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint _value) public returns(bool success);

    function approve(address _spender, uint _value) public returns(bool success);

    function allowance(address _owner, address _spender) public view returns(uint remaining);

    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns(string) {}

    function symbol() public view returns(string) {}

    function decimals() public view returns(uint8) {}

    function totalSupply() public view returns(uint256) {}

    function balanceOf(address _owner) public view returns(uint256) {
        _owner;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        _owner;
        _spender;
    }

    function transfer(address _to, uint256 _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

    function approve(address _spender, uint256 _value) public returns(bool success);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// Oracle Feed Contract
contract orfeed {
    using SafeMath
    for uint256;

    address owner;
    mapping(string => address) freeRateTokenSymbols;
    mapping(string => address) freeRateForexSymbols;
    mapping(string => bytes32) freeRateForexBytes;

    uint256 rateDivide1;
    uint256 rateMultiply1;

    uint256 rateDivide2;
    uint256 rateMultiply2;

    uint256 rateDivide3;
    uint256 rateMultiply3;

    uint256 rateDivide4;
    uint256 rateMultiply4;

    address ethTokenAddress;

    address tokenPriceOracleAddress;
    address synthetixExchangeAddress;

    address tokenPriceOracleAddress2;

    //forex price oracle address. Can be changed by DAO
    address forexPriceOracleAddress;

    //premium price oracle address. Can be changed by DAO
    address premiumSubPriceOracleAddress;

    premiumSubInterface psi;
    IKyberNetworkProxy ki;
    SynthetixExchange se;
    synthConvertInterface s;
    synthetixMain si;
    Kyber kyber;
    Synthetix synthetix;
    Uniswap uniswap;
    ERC20 ethToken;

    /*

    ----


    Below is referenced for understanding for how flow works


    ----

    This will be set in external premium sub contract
    mapping(string => address) feedOwners;
    mapping(string => uint256) feedOwnerDeposits;
    mapping(string => address[]) feedSubscribers;

    //normalsubfee should always remain zero
    uint256 normalSubscriptionFee = 0;

 
    
    //voted on by owner DAO
    uint256 premiumSubscriptionFee = 1;

    //vote on by ownerDAO
    uint256 purchaseUntakenFeedFee = 1;

    //voted on by ownerDAO
    uint256 houseTransactionPercentage = 1;

    */

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    //free ERC20 rates. Can be changed/updated by ownerDAO
    constructor() public payable {
        freeRateTokenSymbols['DAI'] = 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359;
        freeRateTokenSymbols['USDC'] = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;
        freeRateTokenSymbols['MKR'] = 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2;
        freeRateTokenSymbols['LINK'] = 0x514910771af9ca656af840dff83e8264ecf986ca;
        freeRateTokenSymbols['BAT'] = 0x0d8775f648430679a709e98d2b0cb6250d2887ef;
        freeRateTokenSymbols['WBTC'] = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;
        freeRateTokenSymbols['BTC'] = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;
        freeRateTokenSymbols['OMG'] = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;
        freeRateTokenSymbols['ZRX'] = 0xe41d2489571d322189246dafa5ebde1f4699f498;
        freeRateTokenSymbols['TUSD'] = 0x0000000000085d4780B73119b644AE5ecd22b376;
        freeRateTokenSymbols['ETH'] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        freeRateTokenSymbols['WETH'] = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

        //free forex rates. Can be changed/updated by ownerDAO        
        freeRateForexSymbols['USD'] = 0x57ab1e02fee23774580c119740129eac7081e9d3;
        freeRateForexSymbols['EUR'] = 0xd71ecff9342a5ced620049e616c5035f1db98620;
        freeRateForexSymbols['CHF'] = 0x0f83287ff768d1c1e17a42f44d644d7f22e8ee1d;
        freeRateForexSymbols['JPY'] = 0xf6b1c627e95bfc3c1b4c9b825a032ff0fbf3e07d;
        freeRateForexSymbols['GBP'] = 0x97fe22e7341a0cd8db6f6c021a24dc8f4dad855f;

        freeRateForexBytes['USD'] = 0x7355534400000000000000000000000000000000000000000000000000000000;
        freeRateForexBytes['EUR'] = 0x7345555200000000000000000000000000000000000000000000000000000000;
        freeRateForexBytes['CHF'] = 0x7343484600000000000000000000000000000000000000000000000000000000;
        freeRateForexBytes['JPY'] = 0x734a505900000000000000000000000000000000000000000000000000000000;
        freeRateForexBytes['GBP'] = 0x7347425000000000000000000000000000000000000000000000000000000000;

        //when returning rates they will be first divided by and then multiplied by these rates
        rateDivide1 = 100;
        rateMultiply1 = 100;

        rateDivide2 = 100;
        rateMultiply2 = 100;

        rateDivide3 = 100;
        rateMultiply3 = 100;

        rateDivide4 = 100;
        rateMultiply4 = 100;

        //erc20 price oracle address. Can be changed by DAO
        tokenPriceOracleAddress = 0xFd9304Db24009694c680885e6aa0166C639727D6;
        synthetixExchangeAddress = 0x99a46c42689720d9118FF7aF7ce80C2a92fC4f97;

        tokenPriceOracleAddress2 = 0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244;

        //forex price oracle address. Can be changed by DAO
        forexPriceOracleAddress = 0xE86C848De6e4457720A1eb7f37B519010CD26d35;

        //premium price oracle address. Can be changed by DAO
        premiumSubPriceOracleAddress = 0xc011a72400e58ecd99ee497cf89e3775d4bd732f;

        ethTokenAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


        ethToken = ERC20(ethTokenAddress);

        psi = premiumSubInterface(premiumSubPriceOracleAddress);

        ki = IKyberNetworkProxy(tokenPriceOracleAddress);
        se = SynthetixExchange(synthetixExchangeAddress);

        si = synthetixMain(forexPriceOracleAddress);

        kyber = Kyber(tokenPriceOracleAddress); // Kyber oracle
        synthetix = Synthetix(forexPriceOracleAddress); // Synthetix oracle

        uniswap = Uniswap(tokenPriceOracleAddress2);

        owner = msg.sender;
    }

    function() payable {
        throw;
    }

    function getTokenToSynthOutputAmount(ERC20 token, bytes32 synth, uint256 inputAmount) returns(uint256) {
        uint256 ethAmount = kyber.getOutputAmount(token, ethToken, inputAmount);
        uint256 sethAmount = uniswap.getEthToTokenInputPrice(ethAmount);
        uint256 outputAmount = synthetix.getOutputAmount('sETH', synth, sethAmount);
        return outputAmount;
    }

    function getSynthToTokenOutputAmount(bytes32 synth, ERC20 token, uint256 inputAmount) returns(uint256) {
        uint256 sethAmount = synthetix.getOutputAmount(synth, 'sETH', inputAmount);
        uint256 ethAmount = uniswap.getTokenToEthInputPrice(sethAmount);
        uint256 outputAmount = kyber.getOutputAmount(ethToken, token, ethAmount);
        return outputAmount;
    }

    //this will go to a DAO
    function changeOwner(address newOwner) onlyOwner external returns(bool) {
        owner = newOwner;
        return true;
    }

    function updateMulDivConverter1(uint256 newDiv, uint256 newMul) onlyOwner external returns(bool) {
        rateMultiply1 = newMul;
        rateDivide1 = newDiv;
        return true;
    }

    function updateMulDivConverter2(uint256 newDiv, uint256 newMul) onlyOwner external returns(bool) {
        rateMultiply2 = newMul;
        rateDivide2 = newDiv;
        return true;
    }

    function updateMulDivConverter3(uint256 newDiv, uint256 newMul) onlyOwner external returns(bool) {
        rateMultiply3 = newMul;
        rateDivide3 = newDiv;
        return true;
    }

    function updateMulDivConverter4(uint256 newDiv, uint256 newMul) onlyOwner external returns(bool) {
        rateMultiply4 = newMul;
        rateDivide4 = newDiv;
        return true;
    }

    //this will go to a DAO
    function updateTokenOracleAddress(address newOracle) onlyOwner external returns(bool) {
        tokenPriceOracleAddress = newOracle;
        return true;
    }

    function updateEthTokenAddress(address newOracle) onlyOwner external returns(bool) {
        ethTokenAddress = newOracle;
        return true;
    }



    function updateTokenOracleAddress2(address newOracle) onlyOwner external returns(bool) {
        tokenPriceOracleAddress2 = newOracle;
        return true;
    }


    //this will go to a DAO
    function updateForexOracleAddress(address newOracle) onlyOwner external returns(bool) {
        forexPriceOracleAddress = newOracle;
        return true;
    }


    //this will go to a DAO
    function updatePremiumSubOracleAddress(address newOracle) onlyOwner external returns(bool) {
        premiumSubPriceOracleAddress = newOracle;
        return true;
    }

    //this will go to a DAO
    function addFreeToken(string symb, address tokenAddress) onlyOwner external returns(bool) {
        if (freeRateTokenSymbols[symb] != 0x0) {
            //this token already exists
            return false;
        }
        freeRateTokenSymbols[symb] = tokenAddress;
        return true;
    }

    function addFreeCurrency(string symb, address tokenAddress, bytes32 byteCode) onlyOwner external returns(bool) {
        if (freeRateForexSymbols[symb] != 0x0) {
            //this token already exists
            return false;
        }
        freeRateForexSymbols[symb] = tokenAddress;
        freeRateForexBytes[symb] = byteCode;
        return true;
    }

    function removeFreeToken(string symb) onlyOwner external returns(bool) {
        freeRateTokenSymbols[symb] = 0x0;
        return true;
    }


    function removeFreeCurrency(string symb) onlyOwner external returns(bool) {
        freeRateForexSymbols[symb] = 0x0;
        return true;
    }

   

    //returns zero if the rate cannot be found
    function getExchangeRate(string fromSymbol, string toSymbol, string venue, uint256 amount) constant external returns(uint256) {
        bool isFreeFrom = isFree(fromSymbol);
        bool isFreeTo = isFree(toSymbol);
        bool isFreeVenue = isFreeVenueCheck(venue);
        uint256 rate;

        if (isFreeFrom == true && isFreeTo == true && isFreeVenue == true) {
            rate = getFreeExchangeRate(fromSymbol, toSymbol, amount);
            return rate;
        } else {
            //init.sender and msg.sender must have premium
            rate = psi.getExchangeRate(fromSymbol, toSymbol, venue, amount, msg.sender);
            return rate;
        }
    }



    function getTokenAddress(string symbol) constant external returns(address){
        return freeRateTokenSymbols[symbol];
    }

    function getForexAddress(string symbol) constant external returns(address){
         return freeRateForexSymbols[symbol];
    }

    function getSynthBytes32(string symbol)  constant external returns(bytes32){
        return freeRateForexBytes[symbol];
    }

    function getTokenDecimalCount(address tokenAddress) constant external returns(uint256){
        ERC20 thisToken = ERC20(tokenAddress);
        uint256 decimalCount = thisToken.decimals();
    }



    function compareStrings(string memory a, string memory b) public view returns(bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function isFreeVenueCheck(string venueToCheck) returns(bool) {
        string memory blankString = '';
        if (compareStrings(venueToCheck, blankString)) {
            return true;
        } else {
            return false;
        }
    }

    function isFree(string symToCheck) returns(bool) {
        if (freeRateTokenSymbols[symToCheck] != 0x0) {
            return true;
        }
        if (freeRateForexSymbols[symToCheck] != 0x0) {
            return true;
        }
        return false;
    }






    function getFreeExchangeRate(string fromSymb, string toSymb, uint256 amount) returns(uint256) {
        uint256 ethAmount;

         //token to token
        if (freeRateTokenSymbols[fromSymb] != 0x0 && freeRateTokenSymbols[toSymb] != 0x0) {
           
            uint256 toRate = kyber.getOutputAmount(ERC20(freeRateTokenSymbols[fromSymb]), ERC20(freeRateTokenSymbols[toSymb]), amount);
           
        } 

        //token to forex
        else if (freeRateTokenSymbols[fromSymb] != 0x0 && freeRateTokenSymbols[toSymb] == 0x0) {
           
            uint256 toRate2 = getTokenToSynthOutputAmount(ERC20(freeRateTokenSymbols[fromSymb]), freeRateForexBytes[toSymb], amount);
            return toRate2.mul(rateMultiply2).div(rateDivide2);
        } 

        //forex to token
        else if (freeRateTokenSymbols[fromSymb] == 0x0 && freeRateTokenSymbols[toSymb] != 0x0) {
            
            uint256 toRate3 = getSynthToTokenOutputAmount(freeRateForexBytes[fromSymb], ERC20(freeRateTokenSymbols[toSymb]), amount);
            return toRate3.mul(rateMultiply3).div(rateDivide3);
        } 


        //forex to forex

        else if (freeRateTokenSymbols[fromSymb] == 0x0 && freeRateTokenSymbols[toSymb] == 0x0) {
            
            uint256 toRate4 = se.effectiveValue(freeRateForexBytes[fromSymb], amount, freeRateForexBytes[toSymb]);
            return toRate4.mul(rateMultiply4).div(rateDivide4);
        } 
        //something's wrong
        else {
            return 0;
        }
    }
    
    //end contract
}
