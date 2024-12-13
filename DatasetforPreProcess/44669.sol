pragma solidity ^0.5.16;


import "./Owned.sol";
import "./Pausable.sol";
import "./MixinResolver.sol";
import "./interfaces/IBinaryOptionMarketManager.sol";


import "./AddressSetLib.sol";
import "./SafeDecimalMath.sol";


import "./BinaryOptionMarketFactory.sol";
import "./BinaryOptionMarket.sol";
import "./interfaces/IBinaryOptionMarket.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IERC20.sol";



contract BinaryOptionMarketManager is Owned, Pausable, MixinResolver, IBinaryOptionMarketManager {
    

    using SafeMath for uint;
    using AddressSetLib for AddressSetLib.AddressSet;

    

    struct Fees {
        uint poolFee;
        uint creatorFee;
        uint refundFee;
    }

    struct Durations {
        uint maxOraclePriceAge;
        uint expiryDuration;
        uint maxTimeToMaturity;
    }

    struct CreatorLimits {
        uint capitalRequirement;
        uint skewLimit;
    }

    

    Fees public fees;
    Durations public durations;
    CreatorLimits public creatorLimits;

    bool public marketCreationEnabled = true;
    uint public totalDeposited;

    AddressSetLib.AddressSet internal _activeMarkets;
    AddressSetLib.AddressSet internal _maturedMarkets;

    BinaryOptionMarketManager internal _migratingManager;

    

    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 internal constant CONTRACT_SYNTHSUSD = "SynthsUSD";
    bytes32 internal constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant CONTRACT_BINARYOPTIONMARKETFACTORY = "BinaryOptionMarketFactory";

    

    constructor(
        address _owner,
        address _resolver,
        uint _maxOraclePriceAge,
        uint _expiryDuration,
        uint _maxTimeToMaturity,
        uint _creatorCapitalRequirement,
        uint _creatorSkewLimit,
        uint _poolFee,
        uint _creatorFee,
        uint _refundFee
    ) public Owned(_owner) Pausable() MixinResolver(_resolver) {
        
        owner = msg.sender;
        setExpiryDuration(_expiryDuration);
        setMaxOraclePriceAge(_maxOraclePriceAge);
        setMaxTimeToMaturity(_maxTimeToMaturity);
        setCreatorCapitalRequirement(_creatorCapitalRequirement);
        setCreatorSkewLimit(_creatorSkewLimit);
        setPoolFee(_poolFee);
        setCreatorFee(_creatorFee);
        setRefundFee(_refundFee);
        owner = _owner;
    }

    

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](4);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_SYNTHSUSD;
        addresses[2] = CONTRACT_EXRATES;
        addresses[3] = CONTRACT_BINARYOPTIONMARKETFACTORY;
    }

    

    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function _sUSD() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function _factory() internal view returns (BinaryOptionMarketFactory) {
        return BinaryOptionMarketFactory(requireAndGetAddress(CONTRACT_BINARYOPTIONMARKETFACTORY));
    }

    

    function _isKnownMarket(address candidate) internal view returns (bool) {
        return _activeMarkets.contains(candidate) || _maturedMarkets.contains(candidate);
    }

    function numActiveMarkets() external view returns (uint) {
        return _activeMarkets.elements.length;
    }

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory) {
        return _activeMarkets.getPage(index, pageSize);
    }

    function numMaturedMarkets() external view returns (uint) {
        return _maturedMarkets.elements.length;
    }

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory) {
        return _maturedMarkets.getPage(index, pageSize);
    }

    function _isValidKey(bytes32 oracleKey) internal view returns (bool) {
        IExchangeRates exchangeRates = _exchangeRates();

        
        if (exchangeRates.rateForCurrency(oracleKey) != 0) {
            
            if (oracleKey == "sUSD") {
                return false;
            }

            
            (uint entryPoint, , , , ) = exchangeRates.inversePricing(oracleKey);
            if (entryPoint != 0) {
                return false;
            }

            return true;
        }

        return false;
    }

    

    

    function setMaxOraclePriceAge(uint _maxOraclePriceAge) public onlyOwner {
        durations.maxOraclePriceAge = _maxOraclePriceAge;
        emit MaxOraclePriceAgeUpdated(_maxOraclePriceAge);
    }

    function setExpiryDuration(uint _expiryDuration) public onlyOwner {
        durations.expiryDuration = _expiryDuration;
        emit ExpiryDurationUpdated(_expiryDuration);
    }

    function setMaxTimeToMaturity(uint _maxTimeToMaturity) public onlyOwner {
        durations.maxTimeToMaturity = _maxTimeToMaturity;
        emit MaxTimeToMaturityUpdated(_maxTimeToMaturity);
    }

    function setPoolFee(uint _poolFee) public onlyOwner {
        uint totalFee = _poolFee + fees.creatorFee;
        require(totalFee < SafeDecimalMath.unit(), "Total fee must be less than 100%.");
        require(0 < totalFee, "Total fee must be nonzero.");
        fees.poolFee = _poolFee;
        emit PoolFeeUpdated(_poolFee);
    }

    function setCreatorFee(uint _creatorFee) public onlyOwner {
        uint totalFee = _creatorFee + fees.poolFee;
        require(totalFee < SafeDecimalMath.unit(), "Total fee must be less than 100%.");
        require(0 < totalFee, "Total fee must be nonzero.");
        fees.creatorFee = _creatorFee;
        emit CreatorFeeUpdated(_creatorFee);
    }

    function setRefundFee(uint _refundFee) public onlyOwner {
        require(_refundFee <= SafeDecimalMath.unit(), "Refund fee must be no greater than 100%.");
        fees.refundFee = _refundFee;
        emit RefundFeeUpdated(_refundFee);
    }

    function setCreatorCapitalRequirement(uint _creatorCapitalRequirement) public onlyOwner {
        creatorLimits.capitalRequirement = _creatorCapitalRequirement;
        emit CreatorCapitalRequirementUpdated(_creatorCapitalRequirement);
    }

    function setCreatorSkewLimit(uint _creatorSkewLimit) public onlyOwner {
        require(_creatorSkewLimit <= SafeDecimalMath.unit(), "Creator skew limit must be no greater than 1.");
        creatorLimits.skewLimit = _creatorSkewLimit;
        emit CreatorSkewLimitUpdated(_creatorSkewLimit);
    }

    

    function incrementTotalDeposited(uint delta) external onlyActiveMarkets notPaused {
        _systemStatus().requireSystemActive();
        totalDeposited = totalDeposited.add(delta);
    }

    function decrementTotalDeposited(uint delta) external onlyKnownMarkets notPaused {
        _systemStatus().requireSystemActive();
        
        
        
        totalDeposited = totalDeposited.sub(delta);
    }

    

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        bool refundsEnabled,
        uint[2] calldata times, 
        uint[2] calldata bids 
    )
        external
        notPaused
        returns (
            IBinaryOptionMarket 
        )
    {
        _systemStatus().requireSystemActive();
        require(marketCreationEnabled, "Market creation is disabled");
        require(_isValidKey(oracleKey), "Invalid key");

        (uint biddingEnd, uint maturity) = (times[0], times[1]);
        require(maturity <= now + durations.maxTimeToMaturity, "Maturity too far in the future");
        uint expiry = maturity.add(durations.expiryDuration);

        uint initialDeposit = bids[0].add(bids[1]);
        require(now < biddingEnd, "End of bidding has passed");
        require(biddingEnd < maturity, "Maturity predates end of bidding");
        
        
        

        BinaryOptionMarket market = _factory().createMarket(
            msg.sender,
            [creatorLimits.capitalRequirement, creatorLimits.skewLimit],
            oracleKey,
            strikePrice,
            refundsEnabled,
            [biddingEnd, maturity, expiry],
            bids,
            [fees.poolFee, fees.creatorFee, fees.refundFee]
        );
        market.rebuildCache();
        _activeMarkets.add(address(market));

        
        
        totalDeposited = totalDeposited.add(initialDeposit);
        _sUSD().transferFrom(msg.sender, address(market), initialDeposit);

        emit MarketCreated(address(market), msg.sender, oracleKey, strikePrice, biddingEnd, maturity, expiry);
        return market;
    }

    function resolveMarket(address market) external {
        require(_activeMarkets.contains(market), "Not an active market");
        BinaryOptionMarket(market).resolve();
        _activeMarkets.remove(market);
        _maturedMarkets.add(market);
    }

    function cancelMarket(address market) external notPaused {
        require(_activeMarkets.contains(market), "Not an active market");
        address creator = BinaryOptionMarket(market).creator();
        require(msg.sender == creator, "Sender not market creator");
        BinaryOptionMarket(market).cancel(msg.sender);
        _activeMarkets.remove(market);
        emit MarketCancelled(market);
    }

    function expireMarkets(address[] calldata markets) external notPaused {
        for (uint i = 0; i < markets.length; i++) {
            address market = markets[i];

            
            BinaryOptionMarket(market).expire(msg.sender);
            
            
            _maturedMarkets.remove(market);
            emit MarketExpired(market);
        }
    }

    

    function rebuildMarketCaches(BinaryOptionMarket[] calldata marketsToSync) external {
        for (uint i = 0; i < marketsToSync.length; i++) {
            address market = address(marketsToSync[i]);

            
            bytes memory payload = abi.encodeWithSignature("rebuildCache()");
            (bool success, ) = market.call(payload);

            if (!success) {
                
                bytes memory payloadForLegacyCache = abi.encodeWithSignature(
                    "setResolverAndSyncCache(address)",
                    address(resolver)
                );

                
                (bool legacySuccess, ) = market.call(payloadForLegacyCache);
                require(legacySuccess, "Cannot rebuild cache for market");
            }
        }
    }

    function setMarketCreationEnabled(bool enabled) public onlyOwner {
        if (enabled != marketCreationEnabled) {
            marketCreationEnabled = enabled;
            emit MarketCreationEnabledUpdated(enabled);
        }
    }

    function setMigratingManager(BinaryOptionMarketManager manager) public onlyOwner {
        _migratingManager = manager;
    }

    function migrateMarkets(
        BinaryOptionMarketManager receivingManager,
        bool active,
        BinaryOptionMarket[] calldata marketsToMigrate
    ) external onlyOwner {
        uint _numMarkets = marketsToMigrate.length;
        if (_numMarkets == 0) {
            return;
        }
        AddressSetLib.AddressSet storage markets = active ? _activeMarkets : _maturedMarkets;

        uint runningDepositTotal;
        for (uint i; i < _numMarkets; i++) {
            BinaryOptionMarket market = marketsToMigrate[i];
            require(_isKnownMarket(address(market)), "Market unknown.");

            
            markets.remove(address(market));
            runningDepositTotal = runningDepositTotal.add(market.deposited());

            
            market.nominateNewOwner(address(receivingManager));
        }
        
        totalDeposited = totalDeposited.sub(runningDepositTotal);
        emit MarketsMigrated(receivingManager, marketsToMigrate);

        
        receivingManager.receiveMarkets(active, marketsToMigrate);
    }

    function receiveMarkets(bool active, BinaryOptionMarket[] calldata marketsToReceive) external {
        require(msg.sender == address(_migratingManager), "Only permitted for migrating manager.");

        uint _numMarkets = marketsToReceive.length;
        if (_numMarkets == 0) {
            return;
        }
        AddressSetLib.AddressSet storage markets = active ? _activeMarkets : _maturedMarkets;

        uint runningDepositTotal;
        for (uint i; i < _numMarkets; i++) {
            BinaryOptionMarket market = marketsToReceive[i];
            require(!_isKnownMarket(address(market)), "Market already known.");

            market.acceptOwnership();
            markets.add(address(market));
            
            runningDepositTotal = runningDepositTotal.add(market.deposited());
        }
        totalDeposited = totalDeposited.add(runningDepositTotal);
        emit MarketsReceived(_migratingManager, marketsToReceive);
    }

    

    modifier onlyActiveMarkets() {
        require(_activeMarkets.contains(msg.sender), "Permitted only for active markets.");
        _;
    }

    modifier onlyKnownMarkets() {
        require(_isKnownMarket(msg.sender), "Permitted only for known markets.");
        _;
    }

    

    event MarketCreated(
        address market,
        address indexed creator,
        bytes32 indexed oracleKey,
        uint strikePrice,
        uint biddingEndDate,
        uint maturityDate,
        uint expiryDate
    );
    event MarketExpired(address market);
    event MarketCancelled(address market);
    event MarketsMigrated(BinaryOptionMarketManager receivingManager, BinaryOptionMarket[] markets);
    event MarketsReceived(BinaryOptionMarketManager migratingManager, BinaryOptionMarket[] markets);
    event MarketCreationEnabledUpdated(bool enabled);
    event MaxOraclePriceAgeUpdated(uint duration);
    event ExerciseDurationUpdated(uint duration);
    event ExpiryDurationUpdated(uint duration);
    event MaxTimeToMaturityUpdated(uint duration);
    event CreatorCapitalRequirementUpdated(uint value);
    event CreatorSkewLimitUpdated(uint value);
    event PoolFeeUpdated(uint fee);
    event CreatorFeeUpdated(uint fee);
    event RefundFeeUpdated(uint fee);
}
