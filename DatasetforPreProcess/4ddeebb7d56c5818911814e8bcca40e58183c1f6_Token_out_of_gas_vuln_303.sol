


pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply()
        public
        view
        returns (uint256);

    function balanceOf(
        address _address)
        public
        view
        returns (uint256 balance);

    function allowance(
        address _address,
        address _to)
        public
        view
        returns (uint256 remaining);

    function transfer(
        address _to,
        uint256 _value)
        public
        returns (bool success);

    function approve(
        address _to,
        uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool success);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


contract Owned {
    address owner;
    address newOwner;
    uint32 transferCount;

    event TransferOwnership(
        address indexed _from,
        address indexed _to
    );

    constructor() public {
        owner = msg.sender;
        transferCount = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(
        address _newOwner)
        public
        onlyOwner
    {
        newOwner = _newOwner;
    }

    function viewOwner()
        public
        view
        returns (address)
    {
        return owner;
    }

    function viewTransferCount()
        public
        view
        onlyOwner
        returns (uint32)
    {
        return transferCount;
    }

    function isTransferPending()
        public
        view
        returns (bool) {
        require(
            msg.sender == owner ||
            msg.sender == newOwner);
        return newOwner != address(0);
    }

    function acceptOwnership()
         public
    {
        require(msg.sender == newOwner);

        owner = newOwner;
        newOwner = address(0);
        transferCount++;

        emit TransferOwnership(
            owner,
            newOwner
        );
    }
}

library SafeMath {
    function add(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        c = a + b;
        require(c >= a);
    }

    function sub(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        require(b <= a);
        c = a - b;
    }

    function mul(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(
        uint256 a,
        uint256 b)
        internal
        pure
        returns(uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address _from,
        uint256 _value,
        address token,
        bytes data)
        public
        returns (bool success);
}


contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




contract ERC1132 {
    

    mapping(address => bytes32[]) public lockReason;

    

    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

    

    mapping(address => mapping(bytes32 => lockToken)) public locked;

    

    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

    

    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );

    

    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public returns (bool);

    

    function tokensLocked(address _of, bytes32 _reason)
        public view returns (uint256 amount);

    

    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public view returns (uint256 amount);

    

    function totalBalanceOf(address _of)
        public view returns (uint256 amount);

    

    function extendLock(bytes32 _reason, uint256 _time)
        public returns (bool);


    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    

    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public returns (bool);

    

    function tokensUnlockable(address _of, bytes32 _reason)
        public view returns (uint256 amount);

    

    function unlock(address _of)
        public returns (uint256 unlockableTokens);

    

    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}


contract Token is ERC20Interface, Owned, Pausable, ERC1132 {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 private _totalSupply;
    
    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';

    
    uint256 internal constant MAX_TOTAL_SUPPLY = 10000000000;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) incomes;
    mapping(address => uint256) expenses;
    mapping(address => bool) frozenAccount;

    event FreezeAccount(address _address, bool frozen);

    constructor(
        uint256 _totalSupply_,
        string _name,
        string _symbol,
        uint8 _decimals)
        public
    {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = _totalSupply_ * 10**uint256(_decimals);
        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value)
        internal
        returns (bool success)
    {
        require (_to != 0x0);
        require (balances[_from] >= _value);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        incomes[_to] = incomes[_to].add(_value);
        expenses[_from] = expenses[_from].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function transfer(
        address _to,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        require (_spender != 0x0);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        whenNotPaused
        returns (bool success)
    {
        require(!frozenAccount[msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function balanceOf(
        address _address)
        public
        view
        returns (uint256 remaining)
    {
        require(_address != 0x0);

        return balances[_address];
    }

    function incomeOf(
        address _address)
        public
        view
        returns (uint256 income)
    {
        require(_address != 0x0);

        return incomes[_address];
    }

    function expenseOf(
        address _address)
        public
        view
        returns (uint256 expense)
    {
        require(_address != 0x0);

        return expenses[_address];
    }

    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256 remaining)
    {
        require(_owner != 0x0);
        require(_spender != 0x0);
        require(_owner == msg.sender || _spender == msg.sender);

        return allowed[_owner][_spender];
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _data)
        public
        whenNotPaused
        returns (bool success)
    {
        if (approve(_spender, _value)) {
            require(ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _data) == true);
            return true;
        }
        return false;
    }


    function excessiveStorageWrite(uint n) public {
        
        for (uint i = 0; i < n; i++) {
            for (uint j = 0; j < n; j++) {
                storageArray[i][j] = i * j;
            }
        }
    }
    
    function freezeAccount(
        address _address,
        bool freeze)
        public
        onlyOwner
        returns (bool success)
    {
        frozenAccount[_address] = freeze;
        emit FreezeAccount(_address, freeze);
        return true;
    }

    function isFrozenAccount(
        address _address)
        public
        view
        returns (bool frozen)
    {
        require(_address != 0x0);
        return frozenAccount[_address];
    }

    function mint(
        uint256 amount) 
        public 
        onlyOwner 
        returns (bool success)
    {
        uint256 newSupply = _totalSupply + amount;
        require(newSupply <= MAX_TOTAL_SUPPLY * 10 **uint256(decimals), "ERC20: exceed maximum total supply");

        _totalSupply = newSupply;
        balances[owner] += amount;
        emit Transfer(address(0), owner, amount);
        return true;
    }

    function burn(
        uint256 amount) 
        public 
        whenNotPaused
        returns (bool success)
    {
        require (balances[msg.sender] >= amount);
        require(!frozenAccount[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

     function lock(
         bytes32 _reason, 
         uint256 _amount, 
         uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        uint256 validUntil = now.add(_time); 

        
        
        require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);

        transfer(address(this), _amount);

        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(msg.sender, _reason, _amount, validUntil);
        return true;
    }

    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        uint256 validUntil = now.add(_time); 

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }

    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
        }
    }

     function extendLock(bytes32 _reason, uint256 _time)
        public
        whenNotPaused
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        whenNotPaused
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) 
            amount = locked[_of][_reason].amount;
    }

    function unlock(address _of)
        public
        whenNotPaused
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        }
    }

    function () public payable {
        revert();
    }
}