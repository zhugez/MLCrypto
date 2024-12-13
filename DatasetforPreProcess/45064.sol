














pragma solidity ^0.5.4;
import "./MakerV2Base.sol";
import "../../infrastructure/MakerRegistry.sol";

interface IUniswapFactory {
    function getExchange(address _token) external view returns(IUniswapExchange);
}

interface IUniswapExchange {
    function getEthToTokenOutputPrice(uint256 _tokensBought) external view returns (uint256);
    function getEthToTokenInputPrice(uint256 _ethSold) external view returns (uint256);
    function getTokenToEthOutputPrice(uint256 _ethBought) external view returns (uint256);
    function getTokenToEthInputPrice(uint256 _tokensSold) external view returns (uint256);
}


contract MakerV2Loan is MakerV2Base {

    
    GemLike internal mkrToken;
    
    GemLike internal wethToken;
    
    JoinLike internal wethJoin;
    
    JugLike internal jug;
    
    ManagerLike internal cdpManager;
    
    SaiTubLike internal tub;
    
    MakerRegistry internal makerRegistry;
    
    IUniswapExchange internal daiUniswap;
    
    IUniswapExchange internal mkrUniswap;
    
    
    
    mapping(address => mapping(bytes32 => bytes32)) public loanIds;
    
    bool private _notEntered = true;

    
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    

    
    event CdpMigrated(address indexed _wallet, bytes32 _oldCdpId, bytes32 _newVaultId);
    
    event LoanOpened(
        address indexed _wallet,
        bytes32 indexed _loanId,
        address _collateral,
        uint256 _collateralAmount,
        address _debtToken,
        uint256 _debtAmount
    );
    event LoanClosed(address indexed _wallet, bytes32 indexed _loanId);
    event CollateralAdded(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event CollateralRemoved(address indexed _wallet, bytes32 indexed _loanId, address _collateral, uint256 _collateralAmount);
    event DebtAdded(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);
    event DebtRemoved(address indexed _wallet, bytes32 indexed _loanId, address _debtToken, uint256 _debtAmount);


    

    
    modifier onlyModule(BaseWallet _wallet) {
        require(_wallet.authorised(msg.sender), "MV2: sender unauthorized");
        _;
    }

    
    modifier nonReentrant() {
        require(_notEntered, "MV2: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    

    constructor(
        JugLike _jug,
        MakerRegistry _makerRegistry,
        IUniswapFactory _uniswapFactory
    )
        public
    {
        cdpManager = ScdMcdMigrationLike(scdMcdMigration).cdpManager();
        tub = ScdMcdMigrationLike(scdMcdMigration).tub();
        wethJoin = ScdMcdMigrationLike(scdMcdMigration).wethJoin();
        wethToken = wethJoin.gem();
        mkrToken = tub.gov();
        jug = _jug;
        makerRegistry = _makerRegistry;
        daiUniswap = _uniswapFactory.getExchange(address(daiToken));
        mkrUniswap = _uniswapFactory.getExchange(address(mkrToken));
        
        vat.hope(address(daiJoin));
    }

    

    

   
    function openLoan(
        BaseWallet _wallet,
        address _collateral,
        uint256 _collateralAmount,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (bytes32 _loanId)
    {
        verifySupportedCollateral(_collateral);
        require(_debtToken == address(daiToken), "MV2: debt token not DAI");
        _loanId = bytes32(openVault(_wallet, _collateral, _collateralAmount, _debtAmount));
        emit LoanOpened(address(_wallet), _loanId, _collateral, _collateralAmount, _debtToken, _debtAmount);
    }

    
    function addCollateral(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _collateral,
        uint256 _collateralAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        addCollateral(_wallet, uint256(_loanId), _collateralAmount);
        emit CollateralAdded(address(_wallet), _loanId, _collateral, _collateralAmount);
    }

    
    function removeCollateral(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _collateral,
        uint256 _collateralAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        removeCollateral(_wallet, uint256(_loanId), _collateralAmount);
        emit CollateralRemoved(address(_wallet), _loanId, _collateral, _collateralAmount);
    }

    
    function addDebt(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        addDebt(_wallet, uint256(_loanId), _debtAmount);
        emit DebtAdded(address(_wallet), _loanId, _debtToken, _debtAmount);
    }

    
    function removeDebt(
        BaseWallet _wallet,
        bytes32 _loanId,
        address _debtToken,
        uint256 _debtAmount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        updateStabilityFee(uint256(_loanId));
        removeDebt(_wallet, uint256(_loanId), _debtAmount);
        emit DebtRemoved(address(_wallet), _loanId, _debtToken, _debtAmount);
    }

    
    function closeLoan(
        BaseWallet _wallet,
        bytes32 _loanId
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        updateStabilityFee(uint256(_loanId));
        closeVault(_wallet, uint256(_loanId));
        emit LoanClosed(address(_wallet), _loanId);
    }

    

    
    function acquireLoan(
        BaseWallet _wallet,
        bytes32 _loanId
    )
        external
        nonReentrant
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(cdpManager.owns(uint256(_loanId)) == address(_wallet), "MV2: wrong vault owner");
        
        invokeWallet(
            address(_wallet),
            address(cdpManager),
            0,
            abi.encodeWithSignature("give(uint256,address)", uint256(_loanId), address(this))
        );
        require(cdpManager.owns(uint256(_loanId)) == address(this), "MV2: failed give");
        
        assignLoanToWallet(_wallet, _loanId);
    }

    
    function migrateCdp(
        BaseWallet _wallet,
        bytes32 _cup
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
        returns (bytes32 _loanId)
    {
        (uint daiPerMkr, bool ok) = tub.pep().peek();
        if (ok && daiPerMkr != 0) {
            
            uint mkrFee = tub.rap(_cup).wdiv(daiPerMkr);
            
            buyTokens(_wallet, mkrToken, mkrFee, mkrUniswap);
            
            invokeWallet(address(_wallet), address(mkrToken), 0, abi.encodeWithSignature("transfer(address,uint256)", address(scdMcdMigration), mkrFee));
        }
        
        invokeWallet(address(_wallet), address(tub), 0, abi.encodeWithSignature("give(bytes32,address)", _cup, address(scdMcdMigration)));
        
        jug.drip(wethJoin.ilk());
        
        _loanId = bytes32(ScdMcdMigrationLike(scdMcdMigration).migrate(_cup));
        
        _loanId = assignLoanToWallet(_wallet, _loanId);

        emit CdpMigrated(address(_wallet), _cup, _loanId);
    }

    
    function giveVault(
        BaseWallet _wallet,
        bytes32 _loanId
    )
        external
        onlyModule(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        verifyLoanOwner(_wallet, _loanId);
        cdpManager.give(uint256(_loanId), msg.sender);
        clearLoanOwner(_wallet, _loanId);
    }

    

    function toInt(uint256 _x) internal pure returns (int _y) {
        _y = int(_x);
        require(_y >= 0, "MV2: int overflow");
    }

    function assignLoanToWallet(BaseWallet _wallet, bytes32 _loanId) internal returns (bytes32 _assignedLoanId) {
        bytes32 ilk = cdpManager.ilks(uint256(_loanId));
        
        bytes32 existingLoanId = loanIds[address(_wallet)][ilk];
        if (existingLoanId > 0) {
            
            cdpManager.shift(uint256(_loanId), uint256(existingLoanId));
            return existingLoanId;
        }
        
        loanIds[address(_wallet)][ilk] = _loanId;
        return _loanId;
    }

    function clearLoanOwner(BaseWallet _wallet, bytes32 _loanId) internal {
        delete loanIds[address(_wallet)][cdpManager.ilks(uint256(_loanId))];
    }

    function verifyLoanOwner(BaseWallet _wallet, bytes32 _loanId) internal view {
        require(loanIds[address(_wallet)][cdpManager.ilks(uint256(_loanId))] == _loanId, "MV2: unauthorized loanId");
    }

    function verifySupportedCollateral(address _collateral) internal view {
        if (_collateral != ETH_TOKEN_ADDRESS) {
            (bool collateralSupported,,,) = makerRegistry.collaterals(_collateral);
            require(collateralSupported, "MV2: unsupported collateral");
        }
    }

    function buyTokens(
        BaseWallet _wallet,
        GemLike _token,
        uint256 _tokenAmountRequired,
        IUniswapExchange _uniswapExchange
    )
        internal
    {
        
        uint256 tokenBalance = _token.balanceOf(address(_wallet));
        if (tokenBalance < _tokenAmountRequired) {
            
            uint256 etherValueOfTokens = _uniswapExchange.getEthToTokenOutputPrice(_tokenAmountRequired - tokenBalance);
            
            invokeWallet(address(_wallet), address(_uniswapExchange), etherValueOfTokens, abi.encodeWithSignature("ethToTokenSwapOutput(uint256,uint256)", _tokenAmountRequired - tokenBalance, now));
        }
    }

    function joinCollateral(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount,
        bytes32 _ilk
    )
        internal
    {
        
        (JoinLike gemJoin, GemLike collateral) = makerRegistry.getCollateral(_ilk);
        
        if (gemJoin == wethJoin) {
            invokeWallet(address(_wallet), address(wethToken), _collateralAmount, abi.encodeWithSignature("deposit()"));
        }
        
        invokeWallet(
            address(_wallet),
            address(collateral),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", address(this), _collateralAmount)
        );
        
        collateral.approve(address(gemJoin), _collateralAmount);
        
        gemJoin.join(cdpManager.urns(_cdpId), _collateralAmount);
    }

    function joinDebt(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _debtAmount 
    )
        internal
    {
        
        invokeWallet(address(_wallet), address(daiToken), 0, abi.encodeWithSignature("transfer(address,uint256)", address(this), _debtAmount));
        
        daiToken.approve(address(daiJoin), _debtAmount);
        
        
        daiJoin.join(cdpManager.urns(_cdpId), _debtAmount.sub(1));
    }

    function drawAndExitDebt(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _debtAmount,
        uint256 _collateralAmount,
        bytes32 _ilk
    )
        internal
    {
        
        (, uint rate,,,) = vat.ilks(_ilk);
        
        uint daiDebtInRad = _debtAmount.mul(RAY);
        
        cdpManager.frob(_cdpId, toInt(_collateralAmount), toInt(daiDebtInRad.div(rate) + 1));
        
        cdpManager.move(_cdpId, address(this), daiDebtInRad);
        
        daiJoin.exit(address(_wallet), _debtAmount);
    }

    function updateStabilityFee(
        uint256 _cdpId
    )
        internal
    {
        jug.drip(cdpManager.ilks(_cdpId));
    }

    function debt(
        uint256 _cdpId
    )
        internal
        view
        returns (uint256 _fullRepayment, uint256 _maxNonFullRepayment)
    {
        bytes32 ilk = cdpManager.ilks(_cdpId);
        (, uint256 art) = vat.urns(ilk, cdpManager.urns(_cdpId));
        if (art > 0) {
            (, uint rate,,, uint dust) = vat.ilks(ilk);
            _maxNonFullRepayment = art.mul(rate).sub(dust).div(RAY);
            _fullRepayment = art.mul(rate).div(RAY)
                .add(1) 
                .add(art-art.mul(rate).div(RAY).mul(RAY).div(rate)); 
        }
    }

    function collateral(
        uint256 _cdpId
    )
        internal
        view
        returns (uint256 _collateralAmount)
    {
        (_collateralAmount,) = vat.urns(cdpManager.ilks(_cdpId), cdpManager.urns(_cdpId));
    }

    function verifyValidRepayment(
        uint256 _cdpId,
        uint256 _debtAmount
    )
        internal
        view
    {
        (uint256 fullRepayment, uint256 maxRepayment) = debt(_cdpId);
        require(_debtAmount <= maxRepayment || _debtAmount == fullRepayment, "MV2: repay less or full");
    }

     
    
    function openVault(
        BaseWallet _wallet,
        address _collateral,
        uint256 _collateralAmount,
        uint256 _debtAmount
    )
        internal
        returns (uint256 _cdpId)
    {
        
        if (_collateral == ETH_TOKEN_ADDRESS) {
            _collateral = address(wethToken);
        }
        
        bytes32 ilk = makerRegistry.getIlk(_collateral);
        
        _cdpId = uint256(loanIds[address(_wallet)][ilk]);
        if (_cdpId == 0) {
            _cdpId = cdpManager.open(ilk, address(this));
            
            loanIds[address(_wallet)][ilk] = bytes32(_cdpId);
        }
        
        joinCollateral(_wallet, _cdpId, _collateralAmount, ilk);
        
        if (_debtAmount > 0) {
            drawAndExitDebt(_wallet, _cdpId, _debtAmount, _collateralAmount, ilk);
        }
    }

    
    function addCollateral(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount
    )
        internal
    {
        
        joinCollateral(_wallet, _cdpId, _collateralAmount, cdpManager.ilks(_cdpId));
        
        cdpManager.frob(_cdpId, toInt(_collateralAmount), 0);
    }

    
    function removeCollateral(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _collateralAmount
    )
        internal
    {
        
        cdpManager.frob(_cdpId, -toInt(_collateralAmount), 0);
        
        cdpManager.flux(_cdpId, address(this), _collateralAmount);
        
        (JoinLike gemJoin,) = makerRegistry.getCollateral(cdpManager.ilks(_cdpId));
        
        gemJoin.exit(address(_wallet), _collateralAmount);
        
        if (gemJoin == wethJoin) {
            invokeWallet(address(_wallet), address(wethToken), 0, abi.encodeWithSignature("withdraw(uint256)", _collateralAmount));
        }
    }

    
    function addDebt(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _amount
    )
        internal
    {
        
        drawAndExitDebt(_wallet, _cdpId, _amount, 0, cdpManager.ilks(_cdpId));
    }

    
    function removeDebt(
        BaseWallet _wallet,
        uint256 _cdpId,
        uint256 _amount
    )
        internal
    {
        verifyValidRepayment(_cdpId, _amount);
        
        buyTokens(_wallet, daiToken, _amount, daiUniswap);
        
        joinDebt(_wallet, _cdpId, _amount);
        
        (, uint rate,,,) = vat.ilks(cdpManager.ilks(_cdpId));
        
        cdpManager.frob(_cdpId, 0, -toInt(_amount.sub(1).mul(RAY).div(rate)));
    }

    
    function closeVault(
        BaseWallet _wallet,
        uint256 _cdpId
    )
        internal
    {
        (uint256 fullRepayment,) = debt(_cdpId);
        
        if (fullRepayment > 0) {
            removeDebt(_wallet, _cdpId, fullRepayment);
        }
        
        uint256 ink = collateral(_cdpId);
        if (ink > 0) {
            removeCollateral(_wallet, _cdpId, ink);
        }
    }

}