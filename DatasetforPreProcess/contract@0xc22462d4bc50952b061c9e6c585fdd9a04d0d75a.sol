pragma solidity ^0.4.15;

contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

contract MiniMeToken is Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = 'MMT_0.1'; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           require(parentSnapShotBlock < block.number);

           // Do not allow transfer to 0x0 or the token contract itself
           require((_to != 0) && (_to != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer returns false
           var previousBalanceFrom = balanceOfAt(_from, block.number);
           if (previousBalanceFrom < _amount) {
               return false;
           }

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

           return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) constant
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function ()  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}

contract CND is MiniMeToken {
  /**
    * @dev Constructor
  */
  uint256 public constant IS_CND_CONTRACT_MAGIC_NUMBER = 0x1338;
  function CND(address _tokenFactory)
    MiniMeToken(
      _tokenFactory,
      0x0,                      // no parent token
      0,                        // no snapshot block number from parent
      "Cindicator Token",   // Token name
      18,                       // Decimals
      "CND",                    // Symbol
      true                      // Enable transfers
    ) 
    {}

    function() payable {
      require(false);
    }
}

contract MiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Contribution is Controlled, TokenController {
  using SafeMath for uint256;

  struct WhitelistedInvestor {
    uint256 tier;
    bool status;
    uint256 contributedAmount;
  }

  mapping(address => WhitelistedInvestor) investors;
  Tier[4] public tiers;
  uint256 public tierCount;

  MiniMeToken public cnd;
  bool public transferable = false;
  uint256 public October12_2017 = 1507830400;
  address public contributionWallet;
  address public foundersWallet;
  address public advisorsWallet;
  address public bountyWallet;
  bool public finalAllocation;

  uint256 public totalTokensSold;

  bool public paused = false;

  modifier notAllocated() {
    require(finalAllocation == false);
    _;
  }

  modifier endedSale() {
    require(tierCount == 4); //when last one finished it should be equal to 4
    _;
  }

  modifier tokenInitialized() {
    assert(address(cnd) != 0x0);
    _;
  }

  modifier initialized() {
    Tier tier = tiers[tierCount];
    assert(tier.initializedTime() != 0);
    _;
  }
  /// @notice Provides information if contribution is open
  /// @return False if the contribuion is closed
  function contributionOpen() public constant returns(bool) {
    Tier tier = tiers[tierCount];
    return (getBlockTimestamp() >= tier.startTime() && 
           getBlockTimestamp() <= tier.endTime() &&
           tier.finalizedTime() == 0);
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  function Contribution(address _contributionWallet, address _foundersWallet, address _advisorsWallet, address _bountyWallet) {
    require(_contributionWallet != 0x0);
    require(_foundersWallet != 0x0);
    require(_advisorsWallet != 0x0);
    require(_bountyWallet != 0x0);
    contributionWallet = _contributionWallet;
    foundersWallet = _foundersWallet;
    advisorsWallet =_advisorsWallet;
    bountyWallet = _bountyWallet;
    tierCount = 0;
  }
  /// @notice Initializes CND token to contribution
  /// @param _cnd The address of the token contract that you want to set
  function initializeToken(address _cnd) public onlyController {
    assert(CND(_cnd).controller() == address(this));
    assert(CND(_cnd).IS_CND_CONTRACT_MAGIC_NUMBER() == 0x1338);
    require(_cnd != 0x0);
    cnd = CND(_cnd);
  }
  /// @notice Initializes Tier contribution
  /// @param _tierNumber number of tier to initialize
  /// @param _tierAddress address of deployed tier
  function initializeTier(
    uint256 _tierNumber,
    address _tierAddress
  ) public onlyController tokenInitialized
  {
    Tier tier = Tier(_tierAddress);
    assert(tier.controller() == address(this));
    //cannot be more than 4 tiers
    require(_tierNumber >= 0 && _tierNumber <= 3);
    assert(tier.IS_TIER_CONTRACT_MAGIC_NUMBER() == 0x1337);
    // check if tier is not defined
    assert(tiers[_tierNumber] == address(0));
    tiers[_tierNumber] = tier;
    InitializedTier(_tierNumber, _tierAddress);
  }

  /// @notice If anybody sends Ether directly to this contract, consider the sender will
  /// be rejected.
  function () public {
    require(false);
  }
  /// @notice Amount of tokens an investor can purchase
  /// @param _investor investor address
  /// @return number of tokens  
  function investorAmountTokensToBuy(address _investor) public constant returns(uint256) {
    WhitelistedInvestor memory investor = investors[_investor];
    Tier tier = tiers[tierCount];
    uint256 leftToBuy = tier.maxInvestorCap().sub(investor.contributedAmount).mul(tier.exchangeRate());
    return leftToBuy;
  }
  /// @notice Notifies if an investor is whitelisted for contribution
  /// @param _investor investor address
  /// @param _tier tier Number
  /// @return number of tokens 
  function isWhitelisted(address _investor, uint256 _tier) public constant returns(bool) {
    WhitelistedInvestor memory investor = investors[_investor];
    return (investor.tier <= _tier && investor.status);
  }
  /// @notice interface for founders to whitelist investors
  /// @param _addresses array of investors
  /// @param _tier tier Number
  /// @param _status enable or disable
  function whitelistAddresses(address[] _addresses, uint256 _tier, bool _status) public onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
        address investorAddress = _addresses[i];
        require(investors[investorAddress].contributedAmount == 0);
        investors[investorAddress] = WhitelistedInvestor(_tier, _status, 0);
    }
   }
  /// @notice Public function to buy tokens
   function buy() public payable {
     proxyPayment(msg.sender);
   }
  /// use buy function instead of proxyPayment
  /// the param address is useless, it always reassigns to msg.sender
  function proxyPayment(address) public payable 
    notPaused
    initialized
    returns (bool) 
  {
    assert(isCurrentTierCapReached() == false);
    assert(contributionOpen());
    require(isWhitelisted(msg.sender, tierCount));
    doBuy();
    return true;
  }

  /// @notice Notifies the controller about a token transfer allowing the
  ///  controller to react if desired
  /// @return False if the controller does not authorize the transfer
  function onTransfer(address /* _from */, address /* _to */, uint256 /* _amount */) returns(bool) {
    return (transferable || getBlockTimestamp() >= October12_2017 );
  } 

  /// @notice Notifies the controller about an approval allowing the
  ///  controller to react if desired
  /// @return False if the controller does not authorize the approval
  function onApprove(address /* _owner */, address /* _spender */, uint /* _amount */) returns(bool) {
    return (transferable || getBlockTimestamp() >= October12_2017);
  }
  /// @notice Allows founders to set transfers before October12_2017
  /// @param _transferable set True if founders want to let people make transfers
  function allowTransfers(bool _transferable) onlyController {
    transferable = _transferable;
  }
  /// @notice calculates how many tokens left for sale
  /// @return Number of tokens left for tier
  function leftForSale() public constant returns(uint256) {
    Tier tier = tiers[tierCount];
    uint256 weiLeft = tier.cap().sub(tier.totalInvestedWei());
    uint256 tokensLeft = weiLeft.mul(tier.exchangeRate());
    return tokensLeft;
  }
  /// @notice actual method that funds investor and contribution wallet
  function doBuy() internal {
    Tier tier = tiers[tierCount];
    assert(msg.value <= tier.maxInvestorCap());
    address caller = msg.sender;
    WhitelistedInvestor storage investor = investors[caller];
    uint256 investorTokenBP = investorAmountTokensToBuy(caller);
    require(investorTokenBP > 0);

    if(investor.contributedAmount == 0) {
      assert(msg.value >= tier.minInvestorCap());  
    }

    uint256 toFund = msg.value;  
    uint256 tokensGenerated = toFund.mul(tier.exchangeRate());
    // check that at least 1 token will be generated
    require(tokensGenerated >= 1);
    uint256 tokensleftForSale = leftForSale();    

    if(tokensleftForSale > investorTokenBP ) {
      if(tokensGenerated > investorTokenBP) {
        tokensGenerated = investorTokenBP;
        toFund = investorTokenBP.div(tier.exchangeRate());
      }
    }

    if(investorTokenBP > tokensleftForSale) {
      if(tokensGenerated > tokensleftForSale) {
        tokensGenerated = tokensleftForSale;
        toFund = tokensleftForSale.div(tier.exchangeRate());
      }
    }

    investor.contributedAmount = investor.contributedAmount.add(toFund);
    tier.increaseInvestedWei(toFund);
    if (tokensGenerated == tokensleftForSale) {
      finalize();
    }
    
    assert(cnd.generateTokens(caller, tokensGenerated));
    totalTokensSold = totalTokensSold.add(tokensGenerated);

    contributionWallet.transfer(toFund);

    NewSale(caller, toFund, tokensGenerated);

    uint256 toReturn = msg.value.sub(toFund);
    if (toReturn > 0) {
      caller.transfer(toReturn);
      Refund(toReturn);
    }
  }
  /// @notice This method will can be called by the anybody to make final allocation
  /// @return result if everything went succesfully
  function allocate() public notAllocated endedSale returns(bool) {
    finalAllocation = true;
    uint256 totalSupplyCDN = totalTokensSold.mul(100).div(75); // calculate 100%
    uint256 foundersAllocation = totalSupplyCDN.div(5); // 20% goes to founders
    assert(cnd.generateTokens(foundersWallet, foundersAllocation));
    
    uint256 advisorsAllocation = totalSupplyCDN.mul(38).div(1000); // 3.8% goes to advisors
    assert(cnd.generateTokens(advisorsWallet, advisorsAllocation));
    uint256 bountyAllocation = totalSupplyCDN.mul(12).div(1000); // 1.2% goes to  bounty program
    assert(cnd.generateTokens(bountyWallet, bountyAllocation));
    return true;
  }

  /// @notice This method will can be called by the controller after the contribution period
  ///  end or by anybody after the `endTime`. This method finalizes the contribution period
  function finalize() public initialized {
    Tier tier = tiers[tierCount];
    assert(tier.finalizedTime() == 0);
    assert(getBlockTimestamp() >= tier.startTime());
    assert(msg.sender == controller || getBlockTimestamp() > tier.endTime() || isCurrentTierCapReached());

    tier.finalize();
    tierCount++;

    FinalizedTier(tierCount, tier.finalizedTime());
  }
  /// @notice check if tier cap has reached
  /// @return False if it's still open
  function isCurrentTierCapReached() public constant returns(bool) {
    Tier tier = tiers[tierCount];
    return tier.isCapReached();
  }

  //////////
  // Testing specific methods
  //////////

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }



  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyController {
    if (cnd.controller() == address(this)) {
      cnd.claimTokens(_token);
    }

    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    CND token = CND(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  /// @notice Pauses the contribution if there is any issue
  function pauseContribution(bool _paused) onlyController {
    paused = _paused;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event InitializedTier(uint256 _tierNumber, address _tierAddress);
  event FinalizedTier(uint256 _tierCount, uint256 _now);
  event Refund(uint256 _amount);
  
}

contract Tier is Controlled {
  using SafeMath for uint256;
  uint256 public cap;
  uint256 public exchangeRate;
  uint256 public minInvestorCap;
  uint256 public maxInvestorCap;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public initializedTime;
  uint256 public finalizedTime;
  uint256 public totalInvestedWei;
  uint256 public constant IS_TIER_CONTRACT_MAGIC_NUMBER = 0x1337;

  modifier notFinished() {
    require(finalizedTime == 0);
    _;
  }

  function Tier(
    uint256 _cap,
    uint256 _minInvestorCap,
    uint256 _maxInvestorCap,
    uint256 _exchangeRate,
    uint256 _startTime,
    uint256 _endTime
  )
  {
    require(initializedTime == 0);
    assert(_startTime >= getBlockTimestamp());
    require(_startTime < _endTime);
    startTime = _startTime;
    endTime = _endTime;

    require(_cap > 0);
    require(_cap > _maxInvestorCap);
    cap = _cap;

    require(_minInvestorCap < _maxInvestorCap && _maxInvestorCap > 0);
    minInvestorCap = _minInvestorCap;
    maxInvestorCap = _maxInvestorCap;

    require(_exchangeRate > 0);
    exchangeRate = _exchangeRate;

    initializedTime = getBlockTimestamp();
    InitializedTier(_cap, _minInvestorCap, maxInvestorCap, _startTime, _endTime);
  }

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }

  function isCapReached() public constant returns(bool) {
    return totalInvestedWei == cap;
  }

  function finalize() public onlyController {
    require(finalizedTime == 0);
    uint256 currentTime = getBlockTimestamp();
    assert(cap == totalInvestedWei || currentTime > endTime || msg.sender == controller);
    finalizedTime = currentTime;
  }

  function increaseInvestedWei(uint256 _wei) external onlyController notFinished {
    totalInvestedWei = totalInvestedWei.add(_wei);
    IncreaseInvestedWeiAmount(_wei, totalInvestedWei);
  }

  event InitializedTier(
   uint256 _cap,
   uint256 _minInvestorCap, 
   uint256 _maxInvestorCap, 
   uint256 _startTime,
   uint256 _endTime
  );

  function () public {
    require(false);
  }
  event IncreaseInvestedWeiAmount(uint256 _amount, uint256 _newWei);
}
