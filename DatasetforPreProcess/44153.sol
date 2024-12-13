

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanTokenLogicStandard.sol";
import "../../interfaces/IChai.sol";


contract LoanTokenLogicDai is LoanTokenLogicStandard {

    uint256 public constant RAY = 10**27;

    
    

    
    IChai public constant chai = IChai(0x71DD45d9579A499B58aa85F50E5E3B241Ca2d10d);
    IPot public constant pot = IPot(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
    IERC20 public constant dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);


    constructor(
        address _newOwner)
        public
        LoanTokenLogicStandard(_newOwner)
    {}

    

    function mintWithChai(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            depositAmount,
            true 
        );
    }

    function mint(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            depositAmount,
            false 
        );
    }

    function burnToChai(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 chaiAmountPaid)
    {
        return _burnToken(
            burnAmount,
            receiver,
            true 
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        return _burnToken(
            burnAmount,
            receiver,
            false 
        );
    }

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data)
        external
        payable
        nonReentrant
        pausable(msg.sig)
        settlesInterest
        returns (bytes memory)
    {
        require(borrowAmount != 0, "38");

        _dsrWithdraw(borrowAmount);

        IERC20 _dai = _getDai();

        
        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _dai.balanceOf(address(this));

        
        _flTotalAssetSupply = _underlyingBalance()
            .add(totalAssetBorrow());

        
        require(_dai.transfer(
            borrower,
            borrowAmount
        ), "39");

        emit FlashBorrow(borrower, target, loanTokenAddress, borrowAmount);

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        
        (bool success, bytes memory returnData) = arbitraryCaller.call.value(msg.value)(
            abi.encodeWithSelector(
                0xde064e0d, 
                target,
                callData
            )
        );
        require(success, "call failed");

        
        _flTotalAssetSupply = 0;

        
        require(
            address(this).balance >= beforeEtherBalance &&
            _dai.balanceOf(address(this)) >= beforeAssetsBalance,
            "40"
        );

        _dsrDeposit();

        return returnData;
    }

    function _borrow(
        bytes32 loanId,                 
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    
        uint256 collateralTokenSent,    
        address collateralTokenAddress, 
        address borrower,
        address receiver,
        bytes memory ) 
        internal
        returns (ProtocolLike.LoanOpenData memory loanOpenData)
    {
        loanOpenData = super._borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralTokenAddress,
            borrower,
            receiver,
            "" 
        );

        _dsrDeposit();

        return loanOpenData;
    }

    
    function _marginTrade(
        bytes32 loanId,                 
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)
        internal
        returns (ProtocolLike.LoanOpenData memory loanOpenData)
    {
        loanOpenData = super._marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralTokenAddress,
            trader,
            loanDataBytes
        );

        _dsrDeposit();

        return loanOpenData;
    }


    

    
    function dsr()
        public
        view
        returns (uint256)
    {
        return _getPot().dsr()
            .sub(RAY)
            .mul(31536000) 
            .div(10**7);
    }

    
    function chaiPrice()
        public
        view
        returns (uint256)
    {
        return _rChaiPrice()
            .div(10**9);
    }

    function totalSupplyInterestRate(
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        uint256 supplyRate = super.totalSupplyInterestRate(assetSupply);
        return supplyRate != 0 ?
            supplyRate :
            dsr();
    }


    

    function _mintToken(
        address receiver,
        uint256 depositAmount,
        bool withChai)
        internal
        settlesInterest
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));
        uint256 currentChaiPrice;
        IERC20 inAsset;

        if (withChai) {
            inAsset = IERC20(address(_getChai()));
            currentChaiPrice = chaiPrice();
        } else {
            inAsset = IERC20(address(_getDai()));
        }

        require(inAsset.transferFrom(
            msg.sender,
            address(this),
            depositAmount
        ), "18");

        if (withChai) {
            
            depositAmount = depositAmount
                .mul(currentChaiPrice)
                .div(WEI_PRECISION);
        } else {
            _dsrDeposit();
        }

        mintAmount = depositAmount
            .mul(WEI_PRECISION)
            .div(currentPrice);

        _updateCheckpoints(
            receiver,
            balances[receiver],
            _mint(receiver, mintAmount, depositAmount, currentPrice), 
            currentPrice
        );
    }

    function _burnToken(
        uint256 burnAmount,
        address receiver,
        bool toChai)
        internal
        settlesInterest
        returns (uint256 amountPaid)
    {
        require(burnAmount != 0, "19");

        if (burnAmount > balanceOf(msg.sender)) {
            require(burnAmount == uint256(-1), "32");
            burnAmount = balanceOf(msg.sender);
        }

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(0));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(WEI_PRECISION);

        amountPaid = loanAmountOwed;

        bool success;
        if (toChai) {
            
            _dsrDeposit();
            
            IChai _chai = _getChai();
            uint256 chaiBalance = _chai.balanceOf(address(this));
            
            success = _chai.move(
                address(this),
                receiver,
                amountPaid
            );

            
            amountPaid = chaiBalance
                .sub(_chai.balanceOf(address(this)));
        } else {
            _dsrWithdraw(amountPaid);
            success = _getDai().transfer(
                receiver,
                amountPaid
            );

            _dsrDeposit();
        }
        require (success, "37"); 

        _updateCheckpoints(
            msg.sender,
            balances[msg.sender],
            _burn(msg.sender, burnAmount, loanAmountOwed, currentPrice), 
            currentPrice
        );
    }

    
    
    
    
    
    
    
    
    
    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
        returns (uint256)
    {
        _dsrWithdraw(sentAmounts[1]);

        return super._verifyTransfers(
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            withdrawalAmount
        );
    }

    function _rChaiPrice()
        internal
        view
        returns (uint256)
    {
        IPot _pot = _getPot();

        uint256 rho = _pot.rho();
        uint256 chi = _pot.chi();
        if (now > rho) {
            chi = rmul(rpow(_pot.dsr(), now - rho, RAY), chi);
        }

        return chi;
    }

    function _dsrDeposit()
        internal
    {
        uint256 localBalance = _getDai().balanceOf(address(this));
        if (localBalance != 0) {
            _getChai().join(
                address(this),
                localBalance
            );
        }
    }

    function _dsrWithdraw(
        uint256 _value)
        internal
    {
        uint256 localBalance = _getDai().balanceOf(address(this));
        if (_value > localBalance) {
            _getChai().draw(
                address(this),
                _value - localBalance
            );
        }
    }

    function _underlyingBalance()
        internal
        view
        returns (uint256)
    {
        return rmul(
            _getChai().balanceOf(address(this)),
            _rChaiPrice())
            .add(_getDai().balanceOf(address(this)));
    }


    

    function setupChai()
        public
        onlyOwner
    {
        _getDai().approve(address(_getChai()), uint256(-1));
        _dsrDeposit();
    }


    

    
    function _supplyInterestRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        view
        returns (uint256)
    {
        uint256 _dsr = dsr();
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            uint256 localBalance = _getDai().balanceOf(address(this));

            uint256 _utilRate = _utilizationRate(
                assetBorrow,
                assetSupply
                    .sub(localBalance) 
            );

            if (_utilRate > 100 ether) {
                _utilRate = 100 ether;
            }
            _dsr = _dsr
                .mul(100 ether - _utilRate);

            if (localBalance != 0) {
                _utilRate = _utilizationRate(
                    assetBorrow,
                    assetSupply
                );
            }

            uint256 rate = _avgBorrowInterestRate(assetBorrow)
                .mul(_utilRate)
                .mul(SafeMath.sub(WEI_PERCENT_PRECISION, ProtocolLike(bZxContract).lendingFeePercent()))
                .div(WEI_PERCENT_PRECISION);
            return rate
                .add(_dsr)
                .div(WEI_PERCENT_PRECISION);
        } else {
            return _dsr;
        }
    }

    function _getChai()
        internal
        pure
        returns (IChai)
    {
        return chai;
    }

    function _getPot()
        internal
        pure
        returns (IPot)
    {
        return pot;
    }

    function _getDai()
        internal
        pure
        returns (IERC20)
    {
        return dai;
    }

    function rmul(
        uint256 x,
        uint256 y)
        internal
        pure
        returns (uint256 z)
    {
        require(y == 0 || (z = x * y) / y == x);
		z /= RAY;
    }
    function rpow(
        uint256 x,
        uint256 n,
        uint256 base)
        public
        pure
        returns (uint256 z)
    {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if and(iszero(iszero(x)), iszero(eq(div(xx, x), x))) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}
