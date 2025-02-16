pragma solidity ^0.4.17;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished();

    bool public mintingFinished = false;

    address public saleAgent;

    function setSaleAgent(address newSaleAgnet) {
        require(msg.sender == saleAgent || msg.sender == owner);
        saleAgent = newSaleAgnet;
    }

    function mint(address _to, uint256 _amount) returns (bool) {
        require(msg.sender == saleAgent && !mintingFinished);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() returns (bool) {
        require((msg.sender == saleAgent || msg.sender == owner) && !mintingFinished);
        mintingFinished = true;
        MintFinished();
        return true;
    }


}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {

    event Pause();

    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }

}

contract CovestingToken is MintableToken {

    string public constant name = "Covesting";

    string public constant symbol = "COV";

    uint32 public constant decimals = 18;

    mapping (address => uint) public locked;

    function transfer(address _to, uint256 _value) returns (bool) {
        require(locked[msg.sender] < now);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        require(locked[_from] < now);
        return super.transferFrom(_from, _to, _value);
    }

    function lock(address addr, uint periodInDays) {
        require(locked[addr] < now && (msg.sender == saleAgent || msg.sender == addr));
        locked[addr] = now + periodInDays * 1 days;
    }

    function () payable {
        revert();
    }

}

contract StagedCrowdsale is Pausable {

    using SafeMath for uint;

    struct Stage {
    uint hardcap;
    uint price;
    uint invested;
    uint closed;
    }

    uint public start;

    uint public period;

    uint public totalHardcap;

    uint public totalInvested;

    Stage[] public stages;

    function stagesCount() public constant returns(uint) {
        return stages.length;
    }

    function setStart(uint newStart) public onlyOwner {
        start = newStart;
    }

    function setPeriod(uint newPeriod) public onlyOwner {
        period = newPeriod;
    }

    function addStage(uint hardcap, uint price) public onlyOwner {
        require(hardcap > 0 && price > 0);
        Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
        stages.push(stage);
        totalHardcap = totalHardcap.add(stage.hardcap);
    }

    function removeStage(uint8 number) public onlyOwner {
        require(number >=0 && number < stages.length);
        Stage storage stage = stages[number];
        totalHardcap = totalHardcap.sub(stage.hardcap);
        delete stages[number];
        for (uint i = number; i < stages.length - 1; i++) {
            stages[i] = stages[i+1];
        }
        stages.length--;
    }

    function changeStage(uint8 number, uint hardcap, uint price) public onlyOwner {
        require(number >= 0 &&number < stages.length);
        Stage storage stage = stages[number];
        totalHardcap = totalHardcap.sub(stage.hardcap);
        stage.hardcap = hardcap.mul(1 ether);
        stage.price = price;
        totalHardcap = totalHardcap.add(stage.hardcap);
    }

    function insertStage(uint8 numberAfter, uint hardcap, uint price) public onlyOwner {
        require(numberAfter < stages.length);
        Stage memory stage = Stage(hardcap.mul(1 ether), price, 0, 0);
        totalHardcap = totalHardcap.add(stage.hardcap);
        stages.length++;
        for (uint i = stages.length - 2; i > numberAfter; i--) {
            stages[i + 1] = stages[i];
        }
        stages[numberAfter + 1] = stage;
    }

    function clearStages() public onlyOwner {
        for (uint i = 0; i < stages.length; i++) {
            delete stages[i];
        }
        stages.length -= stages.length;
        totalHardcap = 0;
    }

    function lastSaleDate() public constant returns(uint) {
        return start + period * 1 days;
    }

    modifier saleIsOn() {
        require(stages.length > 0 && now >= start && now < lastSaleDate());
        _;
    }

    modifier isUnderHardcap() {
        require(totalInvested <= totalHardcap);
        _;
    }

    function currentStage() public saleIsOn isUnderHardcap constant returns(uint) {
        for(uint i=0; i < stages.length; i++) {
            if(stages[i].closed == 0) {
                return i;
            }
        }
        revert();
    }

}

contract CommonSale is StagedCrowdsale {

    address public multisigWallet;

    uint public minPrice;

    uint public totalTokensMinted;

    CovestingToken public token;

    function setMinPrice(uint newMinPrice) public onlyOwner {
        minPrice = newMinPrice;
    }

    function setMultisigWallet(address newMultisigWallet) public onlyOwner {
        multisigWallet = newMultisigWallet;
    }

    function setToken(address newToken) public onlyOwner {
        token = CovestingToken(newToken);
    }

    function createTokens() public whenNotPaused payable {
        require(msg.value >= minPrice);
        uint stageIndex = currentStage();
        multisigWallet.transfer(msg.value);
        Stage storage stage = stages[stageIndex];
        uint tokens = msg.value.mul(stage.price);
        token.mint(this, tokens);
        token.transfer(msg.sender, tokens);
        totalTokensMinted = totalTokensMinted.add(tokens);
        totalInvested = totalInvested.add(msg.value);
        stage.invested = stage.invested.add(msg.value);
        if(stage.invested >= stage.hardcap) {
            stage.closed = now;
        }
    }

    function() external payable {
        createTokens();
    }

    function retrieveTokens(address anotherToken) public onlyOwner {
        ERC20 alienToken = ERC20(anotherToken);
        alienToken.transfer(multisigWallet, token.balanceOf(this));
    }

}

contract Presale is CommonSale {

    Mainsale public mainsale;

    function setMainsale(address newMainsale) public onlyOwner {
        mainsale = Mainsale(newMainsale);
    }

    function setMultisigWallet(address newMultisigWallet) public onlyOwner {
        multisigWallet = newMultisigWallet;
    }

    function finishMinting() public whenNotPaused onlyOwner {
        token.setSaleAgent(mainsale);
    }

    function() external payable {
        createTokens();
    }

    function retrieveTokens(address anotherToken) public onlyOwner {
        ERC20 alienToken = ERC20(anotherToken);
        alienToken.transfer(multisigWallet, token.balanceOf(this));
    }

}


contract Mainsale is CommonSale {

    enum Currency { BTC, LTC, ZEC, DASH, WAVES, USD, EUR }

    event ExternalSale(
        Currency _currency,
        bytes32 _txIdSha3,
        address indexed _buyer,
        uint256 _amountWei,
        uint256 _tokensE18
    );

    event NotifierChanged(
        address indexed _oldAddress,
        address indexed _newAddress
    );

    // Address that can this crowdsale about changed external conditions.
    address public notifier;

    // currency_code => (sha3_of_tx_id => tokens_e18)
    mapping(uint8 => mapping(bytes32 => uint256)) public externalTxs;

    // Total amount of external contributions (BTC, LTC, USD, etc.) during this crowdsale.
    uint256 public totalExternalSales = 0;

    modifier canNotify() {
        require(msg.sender == owner || msg.sender == notifier);
        _;
    }

    // ----------------

    address public foundersTokensWallet;

    address public bountyTokensWallet;

    uint public foundersTokensPercent;

    uint public bountyTokensPercent;

    uint public percentRate = 100;

    uint public lockPeriod;

    function setLockPeriod(uint newLockPeriod) public onlyOwner {
        lockPeriod = newLockPeriod;
    }

    function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner {
        foundersTokensPercent = newFoundersTokensPercent;
    }

    function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner {
        bountyTokensPercent = newBountyTokensPercent;
    }

    function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner {
        foundersTokensWallet = newFoundersTokensWallet;
    }

    function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner {
        bountyTokensWallet = newBountyTokensWallet;
    }

    function finishMinting() public whenNotPaused onlyOwner {
        uint summaryTokensPercent = bountyTokensPercent + foundersTokensPercent;
        uint mintedTokens = token.totalSupply();
        uint summaryFoundersTokens = mintedTokens.mul(summaryTokensPercent).div(percentRate - summaryTokensPercent);
        uint totalSupply = summaryFoundersTokens + mintedTokens;
        uint foundersTokens = totalSupply.mul(foundersTokensPercent).div(percentRate);
        uint bountyTokens = totalSupply.mul(bountyTokensPercent).div(percentRate);
        token.mint(this, foundersTokens);
        token.lock(foundersTokensWallet, lockPeriod * 1 days);
        token.transfer(foundersTokensWallet, foundersTokens);
        token.mint(this, bountyTokens);
        token.transfer(bountyTokensWallet, bountyTokens);
        totalTokensMinted = totalTokensMinted.add(foundersTokens).add(bountyTokens);
        token.finishMinting();
    }

    //----------------------------------------------------------------------
    // Begin of external sales.

    function setNotifier(address _notifier) public onlyOwner {
        NotifierChanged(notifier, _notifier);
        notifier = _notifier;
    }

    function externalSales(
        uint8[] _currencies,
        bytes32[] _txIdSha3,
        address[] _buyers,
        uint256[] _amountsWei,
        uint256[] _tokensE18
    ) public whenNotPaused canNotify {

        require(_currencies.length > 0);
        require(_currencies.length == _txIdSha3.length);
        require(_currencies.length == _buyers.length);
        require(_currencies.length == _amountsWei.length);
        require(_currencies.length == _tokensE18.length);

        for (uint i = 0; i < _txIdSha3.length; i++) {
            _externalSaleSha3(
                Currency(_currencies[i]),
                _txIdSha3[i],
                _buyers[i],
                _amountsWei[i],
                _tokensE18[i]
            );
        }
    }

    function _externalSaleSha3(
        Currency _currency,
        bytes32 _txIdSha3, // To get bytes32 use keccak256(txId) OR sha3(txId)
        address _buyer,
        uint256 _amountWei,
        uint256 _tokensE18
    ) internal {

        require(_buyer > 0 && _amountWei > 0 && _tokensE18 > 0);

        var txsByCur = externalTxs[uint8(_currency)];

        // If this foreign transaction has been already processed in this contract.
        require(txsByCur[_txIdSha3] == 0);
        txsByCur[_txIdSha3] = _tokensE18;

        uint stageIndex = currentStage();
        Stage storage stage = stages[stageIndex];

        token.mint(this, _tokensE18);
        token.transfer(_buyer, _tokensE18);
        totalTokensMinted = totalTokensMinted.add(_tokensE18);
        totalExternalSales++;

        totalInvested = totalInvested.add(_amountWei);
        stage.invested = stage.invested.add(_amountWei);
        if (stage.invested >= stage.hardcap) {
            stage.closed = now;
        }

        ExternalSale(_currency, _txIdSha3, _buyer, _amountWei, _tokensE18);
    }

    // Get id of currency enum. --------------------------------------------

    function btcId() public constant returns (uint8) {
        return uint8(Currency.BTC);
    }

    function ltcId() public constant returns (uint8) {
        return uint8(Currency.LTC);
    }

    function zecId() public constant returns (uint8) {
        return uint8(Currency.ZEC);
    }

    function dashId() public constant returns (uint8) {
        return uint8(Currency.DASH);
    }

    function wavesId() public constant returns (uint8) {
        return uint8(Currency.WAVES);
    }

    function usdId() public constant returns (uint8) {
        return uint8(Currency.USD);
    }

    function eurId() public constant returns (uint8) {
        return uint8(Currency.EUR);
    }

    // Get token count by transaction id. ----------------------------------

    function _tokensByTx(Currency _currency, string _txId) internal constant returns (uint256) {
        return tokensByTx(uint8(_currency), _txId);
    }

    function tokensByTx(uint8 _currency, string _txId) public constant returns (uint256) {
        return externalTxs[_currency][keccak256(_txId)];
    }

    function tokensByBtcTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.BTC, _txId);
    }

    function tokensByLtcTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.LTC, _txId);
    }

    function tokensByZecTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.ZEC, _txId);
    }

    function tokensByDashTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.DASH, _txId);
    }

    function tokensByWavesTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.WAVES, _txId);
    }

    function tokensByUsdTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.USD, _txId);
    }

    function tokensByEurTx(string _txId) public constant returns (uint256) {
        return _tokensByTx(Currency.EUR, _txId);
    }

    // End of external sales.
    //----------------------------------------------------------------------
}

contract Configurator is Ownable {

    CovestingToken public token;

    Mainsale public mainsale;

    function deploy() public onlyOwner {
        mainsale = new Mainsale();
        token = CovestingToken(0xE2FB6529EF566a080e6d23dE0bd351311087D567);
        mainsale.setToken(token);
        mainsale.addStage(5000,200);
        mainsale.addStage(5000,180);
        mainsale.addStage(10000,170);
        mainsale.addStage(20000,160);
        mainsale.addStage(20000,150);
        mainsale.addStage(40000,130);
        mainsale.setMultisigWallet(0x15A071B83396577cCbd86A979Af7d2aBa9e18970);
        mainsale.setFoundersTokensWallet(0x25ED4f0D260D5e5218D95390036bc8815Ff38262);
        mainsale.setBountyTokensWallet(0x717bfD30f039424B049D918F935DEdD069B66810);
        mainsale.setStart(1511222400);
        mainsale.setPeriod(30);
        mainsale.setLockPeriod(90);
        mainsale.setMinPrice(100000000000000000);
        mainsale.setFoundersTokensPercent(13);
        mainsale.setBountyTokensPercent(5);
        mainsale.setNotifier(owner);
        mainsale.transferOwnership(owner);
    }

}
