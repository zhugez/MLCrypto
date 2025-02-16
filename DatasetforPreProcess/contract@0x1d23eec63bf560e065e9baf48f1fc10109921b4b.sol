pragma solidity ^0.4.26;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UniswapExchangeInterface {
    // Address of IERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to IERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade IERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade IERC20 to IERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade IERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // IERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, IERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) public view returns (uint expectedRate, uint slippageRate);
    function tradeWithHint(IERC20 src, uint srcAmount, IERC20 dest, address destAddress, uint maxDestAmount, uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
    function swapEtherToToken(IERC20 token, uint minRate) public payable returns (uint);
    function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) public returns (uint);
}

interface OrFeedInterface {
    function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
    function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
    function getTokenAddress ( string symbol ) external view returns ( address );
    function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
    function getForexAddress ( string symbol ) external view returns ( address );
}

contract Ourbitrage {
    uint256 internal constant _DEFAULT_MAX_RATE = 8 * (10 ** 27); // 8 billion
    IERC20 internal constant _ETH_TOKEN_ADDRESS = IERC20(0x00EeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE); // IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    KyberNetworkProxyInterface internal _kyber;
    OrFeedInterface internal _orfeed;

    // Uniswap: separate interface for each token type; symbol => interface
    mapping(string => UniswapExchangeInterface) internal _uniswap;

    address internal _owner;
    address internal _feeCollector;

    // Contract Addresses of Tokens for Funding; symbol => token contract address
    mapping(string => address) internal _fundingToken;

    // expressed as a milli-percentage from (0 - 100) * 1000
    mapping(string => uint) internal _allowedSlippage;

    // Tokens currently being used for an arbitration
//    uint internal _tokensInArbitration;

    event Arbitrage(string arbType, address fundingToken, uint profit, uint loss);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    //
    // Initialize
    //

    constructor() public {
        _owner = msg.sender;

//        _kyber = KyberNetworkProxyInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
//        _orfeed = OrFeedInterface(0x3c1935Ebe06Ca18964A5B49B8Cd55A4A71081DE2);
    }

    function () external payable  {}

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function getVersion() public pure returns (string) {
        return "0.0.3";
    }

    //
    // Public
    //

    function getPrice(string from, string to, string venue, uint256 amount) public view returns (uint256) {
        return _orfeed.getExchangeRate(from, to, venue, amount);
    }

    function testBuyEthOnUniswapForToken(string tokenSymbol, uint tokenAmount) public view returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-UNISWAP-EXCHANGE", tokenAmount);
    }

    function testBuyEthOnKyberForToken(string tokenSymbol, uint ethAmount) public view returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-KYBER-EXCHANGE", ethAmount);
    }

    function testSellEthOnUniswapForToken(string tokenSymbol, uint tokenAmount) public view returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-UNISWAP-EXCHANGE", tokenAmount);
    }

    function testSellEthOnKyberForToken(string tokenSymbol, uint ethAmount) public view returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-KYBER-EXCHANGE", ethAmount);
    }

    function uniswapPriceEthForToken(string tokenSymbol, uint tokenAmount) public view returns (uint256) {
        return _uniswap[tokenSymbol].getTokenToEthInputPrice(tokenAmount);
    }

    function uniswapPriceTokenForEth(string tokenSymbol, uint ethAmount) public view returns (uint256) {
        return _uniswap[tokenSymbol].getEthToTokenInputPrice(ethAmount);
    }

    function kyberPriceEthForToken(string tokenSymbol, uint tokenAmount) public view returns (uint expectedRate, uint slippageRate) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        (expectedRate, slippageRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);
    }

    function kyberPriceTokenForEth(string tokenSymbol, uint ethAmount) public view returns (uint expectedRate, uint slippageRate) {
        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
        (expectedRate, slippageRate) = _kyber.getExpectedRate(_ETH_TOKEN_ADDRESS, token, ethAmount);
    }

//    function getEthBalance() public view returns (uint256) {
//        return address(this).balance;
//    }
//
//    function getFundingTokenAddress(string tokenSymbol) public view returns (address) {
//        return _fundingToken[tokenSymbol];
//    }
//
//    function getFundingTokenBalance(string tokenSymbol) public view returns (uint256) {
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        return token.balanceOf(address(this));
//    }
//
//    function getWalletTokenBalance(string tokenSymbol) public view returns (uint256) {
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        return token.balanceOf(msg.sender);
//    }

    //
    // Only Owner; Setup
    //

    function setKyberNetworkProxyInterface(KyberNetworkProxyInterface kyber) public onlyOwner {
        require(address(kyber) != address(0), "Invalid KyberNetworkProxyInterface address");
        _kyber = KyberNetworkProxyInterface(kyber);
    }

    function setOrFeedInterface(OrFeedInterface orfeed) public onlyOwner {
        require(address(orfeed) != address(0), "Invalid OrFeedInterface address");
        _orfeed = OrFeedInterface(orfeed);
    }

    function setFeeCollector(address feeCollector) public onlyOwner {
        require(address(feeCollector) != address(0), "Invalid Fee Collector address");
        _feeCollector = feeCollector;
    }

    function setupFundingToken(string tokenSymbol, address tokenAddress, address uniswapExchangeAddress, uint allowedSlippage) public onlyOwner {
        address ourbitrage = address(this);
        address kyberAddress = address(_kyber);
        IERC20 token = IERC20(tokenAddress);

        // Check for existing funds in contract
        if (_fundingToken[tokenSymbol] != address(0)) {
            uint256 oldTokenBalance = token.balanceOf(ourbitrage);
            require(oldTokenBalance == 0, "You have an existing token balance");
        }

        // Set New Funding Token + Exchange
        _fundingToken[tokenSymbol] = tokenAddress;
        _uniswap[tokenSymbol] = UniswapExchangeInterface(uniswapExchangeAddress);
        _allowedSlippage[tokenSymbol] = allowedSlippage;

        // Approve Exchanges to Transfer Token
        // Mitigate ERC20 Approve front-running attack, by initially setting allowance to 0
        require(token.approve(kyberAddress, 0), "Failed to approve Kyber for token transfer");
        token.approve(kyberAddress, _DEFAULT_MAX_RATE);
        require(token.approve(uniswapExchangeAddress, 0), "Failed to approve Uniswap for token transfer");
        token.approve(uniswapExchangeAddress, _DEFAULT_MAX_RATE);
    }

    //
    // Only Owner; Funding
    //

//    function withdrawETH() public onlyOwner {
//        _withdrawETH(msg.sender);
//    }
//
//    function withdrawToken(string tokenSymbol) public onlyOwner {
//        _withdrawToken(tokenSymbol, msg.sender);
//    }
//
//    function depositFunds(string tokenSymbol, address tokenAddress, uint tokenAmount) public onlyOwner {
//        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been setup");
//        require(_fundingToken[tokenSymbol] == tokenAddress, "Funding Token is not the same as the deposited token type");
//
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        uint256 currentTokenBalance = token.balanceOf(msg.sender);
//        require(tokenAmount <= currentTokenBalance, "User does not have enough funds to deposit");
//
//        // NOTE: Cant do this here, user must approve manually
//        // Mitigate ERC20 Approve front-running attack, by initially setting allowance to 0
////        require(token.approve(address(this), 0), "Failed to approve Ourbitrage Contract transfer Token Funds");
////        token.approve(address(this), tokenAmount);
//
//        // Check that the token transferFrom has succeeded
//        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Failed to transfer Token Funds into Ourbitrage Contract");
//    }

    //
    // Only Owner; Arbitration
    //

    // @dev Buy ETH on Kyber and Sell on Uniswap using Funding Token
//    function arbEthFromKyberToUniswap(string tokenSymbol) public onlyOwner returns (uint, uint) {
//        return _arbEthFromKyberToUniswap(tokenSymbol);
//    }
//
//    // @dev Buy ETH on Uniswap and Sell on Kyber using Funding Token
//    function arbEthFromUniswapToKyber(string tokenSymbol) public onlyOwner returns (uint, uint) {
//        return _arbEthFromUniswapToKyber(tokenSymbol);
//    }

    //
    // Only Owner; Management
    //

//    function transferOwnership(address newOwner) public onlyOwner {
//        _transferOwnership(newOwner);
//    }

    //
    // Private; Funding
    //

//    function _withdrawETH(address receiver) internal {
//        require(receiver != address(0), "Invalid receiver for withdraw");
//        address ourbitrage = address(this);
//        receiver.transfer(ourbitrage.balance);
//    }
//
//    function _withdrawToken(string tokenSymbol, address receiver) internal {
//        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been setup");
//        require(receiver != address(0), "Invalid receiver for withdraw");
//        address ourbitrage = address(this);
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        uint256 currentTokenBalance = token.balanceOf(ourbitrage);
//        token.transfer(receiver, currentTokenBalance);
//    }

    //
    // Private; Arbitration
    //

    // @dev Buy ETH on Kyber and Sell on Uniswap using a Funding-Token specified by "tokenSymbol"
    // @param tokenSymbol The symbol of the Funding-Token to use
//    function _arbEthFromKyberToUniswap(string tokenSymbol) internal returns (uint profit, uint loss) {
//        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been set");
//        require(address(_kyber) != address(0), "Kyber Network Exchange Interface has not been set");
//
//        // Get Amount of Funds in Contract
//        address ourbitrage = address(this);
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        uint256 tokenBalance = token.balanceOf(ourbitrage);
//        require(tokenBalance > 0, "Insufficient funds to process arbitration");
//
//        // Perform Swap
//        uint ethReceived = _buyEthOnKyber(token, tokenBalance);  // Buy ETH on Kyber
//        _sellEthOnUniswap(tokenSymbol, ethReceived);             // Sell ETH on Uniswap
//
//        // Determine Profit/Loss
//        (profit, loss) = _getProfitLoss(token, tokenBalance);
//        emit Arbitrage("ETH-K2U", _fundingToken[tokenSymbol], profit, loss);
//    }
//
//    // @dev Buy ETH on Uniswap and Sell on Kyber using a Funding-Token specified by "tokenSymbol"
//    // @param tokenSymbol The symbol of the Funding-Token to use
//    function _arbEthFromUniswapToKyber(string tokenSymbol) internal returns (uint profit, uint loss) {
//        require(_fundingToken[tokenSymbol] != address(0), "Funding Token has not been set");
//        require(address(_kyber) != address(0), "Kyber Network Exchange Interface has not been set");
//
//        // Get Amount of Funds in Contract
//        address ourbitrage = address(this);
//        IERC20 token = IERC20(_fundingToken[tokenSymbol]);
//        uint256 tokenBalance = token.balanceOf(ourbitrage);
//        require(tokenBalance > 0, "Insufficient funds to process arbitration");
//
//        // Perform Swap
//        uint ethReceived = _buyEthOnUniswap(tokenSymbol, tokenBalance);  // Buy ETH on Uniswap
//        _sellEthOnKyber(token, ethReceived);                             // Sell ETH on Kyber
//
//        // Determine Profit/Loss
//        (profit, loss) = _getProfitLoss(token, tokenBalance);
//        emit Arbitrage("ETH-U2K", _fundingToken[tokenSymbol], profit, loss);
//    }

    //
    // Buy/Sell ETH
    //

    // @dev Buy ETH on Kyber for Funding-Token (SAI/DAI)
//    function _buyEthOnKyber(IERC20 token, uint tokenAmount) internal returns (uint) {
//        address ourbitrage = address(this);
//        uint slippageRate;
//        (, slippageRate) = _kyber.getExpectedRate(token, _ETH_TOKEN_ADDRESS, tokenAmount);
//
//        // Mitigate ERC20 Approve front-running attack, by initially setting allowance to 0
////        require(token.approve(address(_kyber), 0), "Failed to approve KyberNetwork for token transfer");
////        token.approve(address(_kyber), tokenAmount);
//
//        // Send Tokens to Kyber, and receive ETH in contract
////        _tokensInArbitration = tokenAmount;
//        return _kyber.tradeWithHint(IERC20(token), tokenAmount, _ETH_TOKEN_ADDRESS, ourbitrage, _DEFAULT_MAX_RATE, slippageRate, _feeCollector, "PERM");
//    }
//
//    // @dev Sell ETH on Uniswap for Funding-Token (SAI/DAI)
//    function _sellEthOnUniswap(string tokenSymbol, uint ethAmount) internal returns (bool) {
////        uint slippage = _getAllowedSlippage(tokenSymbol, ethAmount);
//        uint minReturn = 1; // _tokensInArbitration - slippage;
//        _uniswap[tokenSymbol].ethToTokenSwapInput.value(ethAmount)(minReturn, block.timestamp);
////        _tokensInArbitration = 0;
//        return true;
//    }
//
//    // @dev Buy ETH on Uniswap for Funding-Token
//    function _buyEthOnUniswap(string tokenSymbol, uint tokenAmount) internal returns (uint) {
////        uint expectedEth = _uniswap[tokenSymbol].getTokenToEthInputPrice(tokenAmount);
////        uint slippage = _getAllowedSlippage(tokenSymbol, expectedEth);
//        uint minEth = 1; // expectedEth - slippage;
//
////        _tokensInArbitration = tokenAmount;
//        return _uniswap[tokenSymbol].tokenToEthSwapInput(tokenAmount, minEth, block.timestamp);
//    }
//
//    // @dev Sell ETH on Kyber for Funding-Token
//    function _sellEthOnKyber(IERC20 token, uint ethAmount) internal returns (uint) {
//        uint slippageRate;
//        (, slippageRate) = _kyber.getExpectedRate(_ETH_TOKEN_ADDRESS, token, ethAmount);
//
//        // Send ETH to Kyber, and receive Funding-Token in contract
//        uint tokensReceived = _kyber.swapEtherToToken.value(ethAmount)(token, slippageRate);
////        _tokensInArbitration = 0;
//        return tokensReceived;
//    }

    //
    // Buy/Sell Token
    //

//    // @dev Buy Token on Kyber for Funding-Token
//    function _buyTokenOnKyber(IERC20 token, uint tokenAmount) internal returns (uint) {
//        return 0;
//    }
//
//    // @dev Sell Token on Uniswap for Funding-Token
//    function _sellTokenOnUniswap(string tokenSymbol, uint ethAmount) internal returns (bool) {
//        return true;
//    }
//
//    // @dev Sell Token on Kyber for Funding-Token
//    function _sellTokenOnKyber(IERC20 token, uint tokenAmount) internal returns (uint) {
//        return 0;
//    }
//
//    // @dev Buy Token on Uniswap for Funding-Token
//    function _buyTokenOnUniswap(string tokenSymbol, uint ethAmount) internal returns (bool) {
//        return true;
//    }

    //
    // Private; Management
    //

//    function _transferOwnership(address newOwner) internal {
//        require(newOwner != address(0));
//        _owner = newOwner;
//    }

    //
    // Private; Misc
    //

//    function _getProfitLoss(IERC20 token, uint oldBalance) internal view returns (uint profit, uint loss) {
//        uint newBalance = token.balanceOf(address(this));
//        if (newBalance < oldBalance) {
//            profit = 0;
//            loss = oldBalance - newBalance;
//        } else {
//            profit = newBalance - oldBalance;
//            loss = 0;
//        }
//    }
//
//    // expressed as a milli-percentage from (0 - 100) * 1000
//    //   where 1 = 0.001%, 1000 = 1%, 12250 = 12.25%
//    //   s = (n * p) / (100 * 1000)
//    function _getAllowedSlippage(string tokenSymbol, uint amount) internal view returns (uint) {
//        return (amount * _allowedSlippage[tokenSymbol]) / 100000;
//    }
}
