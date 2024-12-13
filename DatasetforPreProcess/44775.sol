pragma solidity ^0.5.16;


import "./Owned.sol";
import "./interfaces/IRewardsDistribution.sol";


import "./SafeDecimalMath.sol";


import "./interfaces/IERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IRewardsDistribution.sol";



contract RewardsDistribution is Owned, IRewardsDistribution {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    
    address public authority;

    
    address public synthetixProxy;

    
    address public rewardEscrow;

    
    address public feePoolProxy;

    
    DistributionData[] public distributions;

    
    constructor(
        address _owner,
        address _authority,
        address _synthetixProxy,
        address _rewardEscrow,
        address _feePoolProxy
    ) public Owned(_owner) {
        authority = _authority;
        synthetixProxy = _synthetixProxy;
        rewardEscrow = _rewardEscrow;
        feePoolProxy = _feePoolProxy;
    }

    

    function setSynthetixProxy(address _synthetixProxy) external onlyOwner {
        synthetixProxy = _synthetixProxy;
    }

    function setRewardEscrow(address _rewardEscrow) external onlyOwner {
        rewardEscrow = _rewardEscrow;
    }

    function setFeePoolProxy(address _feePoolProxy) external onlyOwner {
        feePoolProxy = _feePoolProxy;
    }

    
    function setAuthority(address _authority) external onlyOwner {
        authority = _authority;
    }

    

    
    function addRewardDistribution(address destination, uint amount) external onlyOwner returns (bool) {
        require(destination != address(0), "Cant add a zero address");
        require(amount != 0, "Cant add a zero amount");

        DistributionData memory rewardsDistribution = DistributionData(destination, amount);
        distributions.push(rewardsDistribution);

        emit RewardDistributionAdded(distributions.length - 1, destination, amount);
        return true;
    }

    
    function removeRewardDistribution(uint index) external onlyOwner {
        require(index <= distributions.length - 1, "index out of bounds");

        
        for (uint i = index; i < distributions.length - 1; i++) {
            distributions[i] = distributions[i + 1];
        }
        distributions.length--;

        
        
        
        
    }

    
    function editRewardDistribution(
        uint index,
        address destination,
        uint amount
    ) external onlyOwner returns (bool) {
        require(index <= distributions.length - 1, "index out of bounds");

        distributions[index].destination = destination;
        distributions[index].amount = amount;

        return true;
    }

    function distributeRewards(uint amount) external returns (bool) {
        require(amount > 0, "Nothing to distribute");
        require(msg.sender == authority, "Caller is not authorised");
        require(rewardEscrow != address(0), "RewardEscrow is not set");
        require(synthetixProxy != address(0), "SynthetixProxy is not set");
        require(feePoolProxy != address(0), "FeePoolProxy is not set");
        require(
            IERC20(synthetixProxy).balanceOf(address(this)) >= amount,
            "RewardsDistribution contract does not have enough tokens to distribute"
        );

        uint remainder = amount;

        
        for (uint i = 0; i < distributions.length; i++) {
            if (distributions[i].destination != address(0) || distributions[i].amount != 0) {
                remainder = remainder.sub(distributions[i].amount);

                
                IERC20(synthetixProxy).transfer(distributions[i].destination, distributions[i].amount);

                
                bytes memory payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);

                
                (bool success, ) = distributions[i].destination.call(payload);

                if (!success) {
                    
                }
            }
        }

        
        IERC20(synthetixProxy).transfer(rewardEscrow, remainder);

        
        IFeePool(feePoolProxy).setRewardsToDistribute(remainder);

        emit RewardsDistributed(amount);
        return true;
    }

    

    
    function distributionsLength() external view returns (uint) {
        return distributions.length;
    }

    

    event RewardDistributionAdded(uint index, address destination, uint amount);
    event RewardsDistributed(uint amount);
}
