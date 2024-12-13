

pragma solidity >=0.4.23 <0.6.0;

import "./interfaces/ERC20Interface.sol";
import "./Mocks/SafeMath.sol";

contract Vault {
    using SafeMath for uint256;
    ERC20Interface private erc20;
    address public erc20Address;
    uint256 public totalAmount = 0; 
    uint256 public totalBalance = 0; 

    struct Commitment {                 
        uint256         status;             
        uint256         amount;             
        address payable sender;         
        uint256         effectiveTime;      
        uint256         timestamp;          
        uint256         canEndorse;
        uint256         lockable;           
        uint256         params1;
        uint256         params2;
        uint256         params3;
        address         params4;
    }
    
    
    mapping(bytes32 => Commitment) private commitments; 
    address public operator;
    address public shakerContractAddress;
    address public disputeManagerAddress;

    event Deposit(address indexed sender, bytes32 indexed hashkey, uint256 amount, uint256 timestamp);
    event Withdrawal(string indexed commitment, uint256 fee, uint256 amount, uint256 timestamp);

    function sendDepositEvent(address _sender, bytes32 _hashkey, uint256 _amount, uint256 _timestamp) external onlyShakerAndDisputManager {
      emit Deposit(_sender, _hashkey, _amount, _timestamp);
    }

    function sendWithdrawEvent(string calldata _commitment, uint256 _fee, uint256 _amount, uint256 _timestamp) external onlyShakerAndDisputManager {
      emit Withdrawal(_commitment, _fee, _amount, _timestamp);
    }

    modifier onlyOperator {
        require(msg.sender == operator, "Only operator can call this function.");
        _;
    }

    modifier onlyShakerAndDisputManager {
        require(msg.sender == shakerContractAddress || msg.sender == disputeManagerAddress, "Only bitcheck contract or dispute manager can call this function.");
        _;
    }

    constructor(address _erc20Address) public {
        operator = msg.sender;
        erc20Address = _erc20Address;
        erc20 = ERC20Interface(erc20Address);
    }

    function setStatus(bytes32 _hashkey, uint256 _status) external onlyShakerAndDisputManager {
        commitments[_hashkey].status = _status;
    }
    
    function setAmount(bytes32 _hashkey, uint256 _amount) external onlyShakerAndDisputManager {
        commitments[_hashkey].amount = _amount;
    }
    
    function setSender(bytes32 _hashkey, address payable _sender) external onlyShakerAndDisputManager {
        commitments[_hashkey].sender = _sender;
    }
    
    function setEffectiveTime(bytes32 _hashkey, uint256 _effectiveTime) external onlyShakerAndDisputManager {
        commitments[_hashkey].effectiveTime = _effectiveTime;
    }
    
    function setTimestamp(bytes32 _hashkey, uint256 _timestamp) external onlyShakerAndDisputManager {
        commitments[_hashkey].timestamp = _timestamp;
    }
    
    function setCanEndorse(bytes32 _hashkey, uint256 _canEndorse) external onlyShakerAndDisputManager {
        commitments[_hashkey].canEndorse = _canEndorse;
    }
    
    function setLockable(bytes32 _hashkey, uint256 _lockable) external onlyShakerAndDisputManager {
        commitments[_hashkey].lockable = _lockable;
    }

    function setParams1(bytes32 _hashkey, uint256 _params1) external onlyShakerAndDisputManager {
        commitments[_hashkey].params1 = _params1;
    }

    function setParams2(bytes32 _hashkey, uint256 _params2) external onlyShakerAndDisputManager {
        commitments[_hashkey].params2 = _params2;
    }

    function setParams3(bytes32 _hashkey, uint256 _params3) external onlyShakerAndDisputManager {
        commitments[_hashkey].params3 = _params3;
    }

    function setParams4(bytes32 _hashkey, address _params4) external onlyShakerAndDisputManager {
        commitments[_hashkey].params4 = _params4;
    }
    
    
    function getStatus(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].status;
    }
    
    function getAmount(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].amount;
    }
    
    function getSender(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(address payable) {
        return commitments[_hashkey].sender;
    }
    
    function getEffectiveTime(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].effectiveTime;
    }
    
    function getTimestamp(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].timestamp;
    }
    
    function getCanEndorse(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].canEndorse;
    }
    
    function getLockable(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].lockable;
    }    

    function getParams1(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].params1;
    }

    function getParams2(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].params2;
    }

    function getParams3(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(uint256) {
        return commitments[_hashkey].params3;
    }

    function getParams4(bytes32 _hashkey) external view onlyShakerAndDisputManager returns(address) {
        return commitments[_hashkey].params4;
    }
    
    function updateOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function updateShakerAddress(address _shaker, uint256 _allowance) external onlyOperator returns(bool) {
        shakerContractAddress = _shaker;
        
        safeApprove(erc20Address, _shaker, _allowance);
        return true;
    }

    function updateDisputeManager(address _disputeManagerAddress, uint256 _allowance) external onlyOperator returns(bool) {
        disputeManagerAddress = _disputeManagerAddress;
        
        safeApprove(erc20Address, _disputeManagerAddress, _allowance);
        return true;
    }

    function getShakerAllowance() external view returns(uint256) {
      return erc20.allowance(address(this), shakerContractAddress);
    }
    
    function getDisputeManagerAllowance() external view returns(uint256) {
        return erc20.allowance(address(this), disputeManagerAddress);
    }

    function addTotalAmount(uint256 _amount) external onlyShakerAndDisputManager {
        totalAmount = totalAmount.add(_amount);
    }

    function addTotalBalance(uint256 _amount) external onlyShakerAndDisputManager {
        totalBalance = totalBalance.add(_amount);
    }

    function subTotalBalance(uint256 _amount) external onlyShakerAndDisputManager {
        totalBalance = totalBalance.sub(_amount);
    }

    function safeApprove(address token, address to, uint value) internal {
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
}
