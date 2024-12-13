

pragma solidity ^0.4.18;

import "./SecurityTransferAgentInterface.sol";
import "./ERC677Token.sol";
import "zeppelin/contracts/math/SafeMath.sol";


contract CheckpointToken is ERC677Token {
  using SafeMath for uint256; 

  
  string public name;
  
  string public symbol;
  
  uint256 public decimals;
  
  SecurityTransferAgent public transactionVerifier;

  
  
  struct Checkpoint {
    uint256 checkpointID;
    uint256 value;
  }
  
  mapping (address => Checkpoint[]) public tokenBalances;
  
  Checkpoint[] public tokensTotal;
  
  
  uint256 public currentCheckpointID;

  
  mapping (address => mapping (address => uint256)) public allowed;

  
  function CheckpointToken(string _name, string _symbol, uint256 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  

  
  function allowance(address owner, address spender) public view returns (uint256) {
    return allowed[owner][spender];
  }

  
  function approve(address spender, uint256 value) public returns (bool) {
    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

  
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= allowed[from][msg.sender]);

    value = verifyTransaction(from, to, value);

    transferInternal(from, to, value);
    Transfer(from, to, value);
    return true;
  }

  
  function transfer(address to, uint256 value) public returns (bool) {
    value = verifyTransaction(msg.sender, to, value);

    transferInternal(msg.sender, to, value);
    Transfer(msg.sender, to, value);
    return true;
  }

  
  function totalSupply() public view returns (uint256 tokenCount) {
    tokenCount = balanceAtCheckpoint(tokensTotal, currentCheckpointID);
  }

  
  function totalSupplyAt(uint256 checkpointID) public view returns (uint256 tokenCount) {
    tokenCount = balanceAtCheckpoint(tokensTotal, checkpointID);
  }

  
  function balanceOf(address owner) public view returns (uint256 balance) {
    balance = balanceAtCheckpoint(tokenBalances[owner], currentCheckpointID);
  }

  
  function balanceAt(address owner, uint256 checkpointID) public view returns (uint256 balance) {
    balance = balanceAtCheckpoint(tokenBalances[owner], checkpointID);
  }

  
  function increaseApproval(address spender, uint addedValue) public returns (bool) {
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  
  function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][spender];
    if (subtractedValue > oldValue) {
      allowed[msg.sender][spender] = 0;
    } else {
      allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  
  function increaseApproval(address spender, uint addedValue, bytes data) public returns (bool) {
    require(spender != address(this));

    increaseApproval(spender, addedValue);

    require(spender.call(data));

    return true;
  }

  
  function decreaseApproval(address spender, uint subtractedValue, bytes data) public returns (bool) {
    require(spender != address(this));

    decreaseApproval(spender, subtractedValue);

    require(spender.call(data));

    return true;
  }

  

  function balanceAtCheckpoint(Checkpoint[] storage checkpoints, uint256 checkpointID) internal returns (uint256 balance) {
    uint256 currentCheckpointID;
    (currentCheckpointID, balance) = getCheckpoint(checkpoints, checkpointID);
  }

  function verifyTransaction(address from, address to, uint256 value) internal returns (uint256) {
    if (address(transactionVerifier) != address(0)) {
      value = transactionVerifier.verify(from, to, value);
    }

    
    return value;
  }

  function transferInternal(address from, address to, uint256 value) internal {
    uint256 fromBalance = balanceOf(from);
    uint256 toBalance = balanceOf(to);

    setCheckpoint(tokenBalances[from], fromBalance.sub(value));
    setCheckpoint(tokenBalances[to], toBalance.add(value));
  }

  function createCheckpoint() internal returns (uint256 checkpointID) {
    currentCheckpointID = currentCheckpointID + 1;
    return currentCheckpointID;
  }


  

  function setCheckpoint(Checkpoint[] storage checkpoints, uint256 newValue) internal {
    if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].checkpointID < currentCheckpointID)) {
      checkpoints.push(Checkpoint(currentCheckpointID, newValue));
    } else {
       checkpoints[checkpoints.length.sub(1)] = Checkpoint(currentCheckpointID, newValue);
    }
  }

  function getCheckpoint(Checkpoint[] storage checkpoints, uint256 checkpointID) internal returns (uint256 checkpointID_, uint256 value) {
    if (checkpoints.length == 0) {
      return (0, 0);
    }

    
    if (checkpointID >= checkpoints[checkpoints.length.sub(1)].checkpointID) {
      return (checkpoints[checkpoints.length.sub(1)].checkpointID, checkpoints[checkpoints.length.sub(1)].value);
    }

    if (checkpointID < checkpoints[0].checkpointID) {
      return (0, 0);
    }

    
    uint256 min = 0;
    uint256 max = checkpoints.length.sub(1);
    while (max > min) {
      uint256 mid = (max.add(min.add(1))).div(2);
      if (checkpoints[mid].checkpointID <= checkpointID) {
        min = mid;
      } else {
        max = mid.sub(1);
      }
    }

    return (checkpoints[min].checkpointID, checkpoints[min].value);
  }
}
