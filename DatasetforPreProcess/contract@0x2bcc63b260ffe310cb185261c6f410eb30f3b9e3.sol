pragma solidity 0.4.25;

// File: contracts/saga/interfaces/IModelDataSource.sol

/**
 * @title Model Data Source Interface.
 */
interface IModelDataSource {
    /**
     * @dev Get interval parameters.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval minimum amount of SGA.
     * @return Interval maximum amount of SGA.
     * @return Interval minimum amount of SDR.
     * @return Interval maximum amount of SDR.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getInterval(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /**
     * @dev Get interval alpha and beta.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getIntervalCoefs(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256);

    /**
     * @dev Get the amount of SGA required for moving to the next minting-point.
     * @param _rowNum Interval row index.
     * @return Required amount of SGA.
     */
    function getRequiredMintAmount(uint256 _rowNum) external view returns (uint256);
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity-v1.12.0/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/saga/ModelDataSource.sol

/**
 * Details of usage of licenced software see here: https://www.saga.org/software/readme_v1
 */

/**
 * @title Model Data Source.
 */
contract ModelDataSource is IModelDataSource, Claimable {
    string public constant VERSION = "1.0.0";

    struct Interval {
        uint256 minN;
        uint256 maxN;
        uint256 minR;
        uint256 maxR;
        uint256 alpha;
        uint256 beta;
    }

    bool public intervalListsLocked;
    Interval[11][105] public intervalLists;

    /**
     * @dev Lock the interval lists.
     */
    function lock() external onlyOwner {
        intervalListsLocked = true;
    }

    /**
     * @dev Set interval parameters.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @param _minN   Interval minimum amount of SGA.
     * @param _maxN   Interval maximum amount of SGA.
     * @param _minR   Interval minimum amount of SDR.
     * @param _maxR   Interval maximum amount of SDR.
     * @param _alpha  Interval alpha value (scaled up).
     * @param _beta   Interval beta  value (scaled up).
     */
    function setInterval(uint256 _rowNum, uint256 _colNum, uint256 _minN, uint256 _maxN, uint256 _minR, uint256 _maxR, uint256 _alpha, uint256 _beta) external onlyOwner {
        require(!intervalListsLocked, "interval lists are already locked");
        intervalLists[_rowNum][_colNum] = Interval({minN: _minN, maxN: _maxN, minR: _minR, maxR: _maxR, alpha: _alpha, beta: _beta});
    }

    /**
     * @dev Get interval parameters.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval minimum amount of SGA.
     * @return Interval maximum amount of SGA.
     * @return Interval minimum amount of SDR.
     * @return Interval maximum amount of SDR.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getInterval(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        Interval storage interval = intervalLists[_rowNum][_colNum];
        return (interval.minN, interval.maxN, interval.minR, interval.maxR, interval.alpha, interval.beta);
    }

    /**
     * @dev Get interval alpha and beta.
     * @param _rowNum Interval row index.
     * @param _colNum Interval column index.
     * @return Interval alpha value (scaled up).
     * @return Interval beta  value (scaled up).
     */
    function getIntervalCoefs(uint256 _rowNum, uint256 _colNum) external view returns (uint256, uint256) {
        Interval storage interval = intervalLists[_rowNum][_colNum];
        return (interval.alpha, interval.beta);
    }

    /**
     * @dev Get the amount of SGA required for moving to the next minting-point.
     * @param _rowNum Interval row index.
     * @return Required amount of SGA.
     */
    function getRequiredMintAmount(uint256 _rowNum) external view returns (uint256) {
        uint256 currMaxN = intervalLists[_rowNum + 0][0].maxN;
        uint256 nextMinN = intervalLists[_rowNum + 1][0].minN;
        assert(nextMinN >= currMaxN);
        return nextMinN - currMaxN;
    }
}

