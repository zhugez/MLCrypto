pragma solidity ^0.4.18;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract SkinBase is Pausable {

    struct Skin {
        uint128 appearance;
        uint64 cooldownEndTime;
        uint64 mixingWithId;
    }

    // All skins, mapping from skin id to skin apprance
    mapping (uint256 => Skin) skins;

    // Mapping from skin id to owner
    mapping (uint256 => address) public skinIdToOwner;

    // Whether a skin is on sale
    mapping (uint256 => bool) public isOnSale;

    // Number of all total valid skins
    // skinId 0 should not correspond to any skin, because skin.mixingWithId==0 indicates not mixing
    uint256 public nextSkinId = 1;  

    // Number of skins an account owns
    mapping (address => uint256) public numSkinOfAccounts;

    // // Give some skins to init account for unit tests
    // function SkinBase() public {
    //     address account0 = 0x627306090abaB3A6e1400e9345bC60c78a8BEf57;
    //     address account1 = 0xf17f52151EbEF6C7334FAD080c5704D77216b732;

    //     // Create simple skins
    //     Skin memory skin = Skin({appearance: 0, cooldownEndTime:0, mixingWithId: 0});
    //     for (uint256 i = 1; i <= 15; i++) {
    //         if (i < 10) {
    //             skin.appearance = uint128(i);
    //             if (i < 7) { 
    //                 skinIdToOwner[i] = account0;
    //                 numSkinOfAccounts[account0] += 1;
    //             } else {  
    //                 skinIdToOwner[i] = account1;
    //                 numSkinOfAccounts[account1] += 1;
    //             }
    //         } else {  
    //             skin.appearance = uint128(block.blockhash(block.number - i + 9));
    //             skinIdToOwner[i] = account1;
    //             numSkinOfAccounts[account1] += 1;
    //         }
    //         skins[i] = skin;
    //         isOnSale[i] = false;
    //         nextSkinId += 1;
    //     }
    // } 

    // Get the i-th skin an account owns, for off-chain usage only
    function skinOfAccountById(address account, uint256 id) external view returns (uint256) {
       uint256 count = 0;
       uint256 numSkinOfAccount = numSkinOfAccounts[account];
       require(numSkinOfAccount > 0);
       require(id < numSkinOfAccount);
       for (uint256 i = 1; i < nextSkinId; i++) {
           if (skinIdToOwner[i] == account) {
               // This skin belongs to current account
               if (count == id) {
                   // This is the id-th skin of current account, a.k.a, what we need
                    return i;
               } 
               count++;
           }
        }
        revert();
    }

    // Get skin by id
    function getSkin(uint256 id) public view returns (uint128, uint64, uint64) {
        require(id > 0);
        require(id < nextSkinId);
        Skin storage skin = skins[id];
        return (skin.appearance, skin.cooldownEndTime, skin.mixingWithId);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(this.balance);
    }
}
contract MixFormulaInterface {
    function calcNewSkinAppearance(uint128 x, uint128 y) public pure returns (uint128);

    // create random appearance
    function randomSkinAppearance() public view returns (uint128);

    // bleach
    function bleachAppearance(uint128 appearance, uint128 attributes) public pure returns (uint128);
}
contract SkinMix is SkinBase {

    // Mix formula
    MixFormulaInterface public mixFormula;


    // Pre-paid ether for synthesization, will be returned to user if the synthesization failed (minus gas).
    uint256 public prePaidFee = 1000000 * 3000000000; // (1million gas * 3 gwei)

    // Events
    event MixStart(address account, uint256 skinAId, uint256 skinBId);
    event AutoMix(address account, uint256 skinAId, uint256 skinBId, uint64 cooldownEndTime);
    event MixSuccess(address account, uint256 skinId, uint256 skinAId, uint256 skinBId);

    // Set mix formula contract address 
    function setMixFormulaAddress(address mixFormulaAddress) external onlyOwner {
        mixFormula = MixFormulaInterface(mixFormulaAddress);
    }

    // setPrePaidFee: set advance amount, only owner can call this
    function setPrePaidFee(uint256 newPrePaidFee) external onlyOwner {
        prePaidFee = newPrePaidFee;
    }

    // _isCooldownReady: check whether cooldown period has been passed
    function _isCooldownReady(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].cooldownEndTime <= uint64(now)) && (skins[skinBId].cooldownEndTime <= uint64(now));
    }

    // _isNotMixing: check whether two skins are in another mixing process
    function _isNotMixing(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].mixingWithId == 0) && (skins[skinBId].mixingWithId == 0);
    }

    // _setCooldownTime: set new cooldown time
    function _setCooldownEndTime(uint256 skinAId, uint256 skinBId) private {
        uint256 end = now + 5 minutes;
        // uint256 end = now;
        skins[skinAId].cooldownEndTime = uint64(end);
        skins[skinBId].cooldownEndTime = uint64(end);
    }

    // _isValidSkin: whether an account can mix using these skins
    // Make sure two things:
    // 1. these two skins do exist
    // 2. this account owns these skins
    function _isValidSkin(address account, uint256 skinAId, uint256 skinBId) private view returns (bool) {
        // Make sure those two skins belongs to this account
        if (skinAId == skinBId) {
            return false;
        }
        if ((skinAId == 0) || (skinBId == 0)) {
            return false;
        }
        if ((skinAId >= nextSkinId) || (skinBId >= nextSkinId)) {
            return false;
        }
        return (skinIdToOwner[skinAId] == account) && (skinIdToOwner[skinBId] == account);
    }

    // _isNotOnSale: whether a skin is not on sale
    function _isNotOnSale(uint256 skinId) private view returns (bool) {
        return (isOnSale[skinId] == false);
    }

    // mix  
    function mix(uint256 skinAId, uint256 skinBId) public whenNotPaused {

        // Check whether skins are valid
        require(_isValidSkin(msg.sender, skinAId, skinBId));

        // Check whether skins are neither on sale
        require(_isNotOnSale(skinAId) && _isNotOnSale(skinBId));

        // Check cooldown
        require(_isCooldownReady(skinAId, skinBId));

        // Check these skins are not in another process
        require(_isNotMixing(skinAId, skinBId));

        // Set new cooldown time
        _setCooldownEndTime(skinAId, skinBId);

        // Mark skins as in mixing
        skins[skinAId].mixingWithId = uint64(skinBId);
        skins[skinBId].mixingWithId = uint64(skinAId);

        // Emit MixStart event
        MixStart(msg.sender, skinAId, skinBId);
    }

    // Mixing auto
    function mixAuto(uint256 skinAId, uint256 skinBId) public payable whenNotPaused {
        require(msg.value >= prePaidFee);

        mix(skinAId, skinBId);

        Skin storage skin = skins[skinAId];

        AutoMix(msg.sender, skinAId, skinBId, skin.cooldownEndTime);
    }

    // Get mixing result, return the resulted skin id
    function getMixingResult(uint256 skinAId, uint256 skinBId) public whenNotPaused {
        // Check these two skins belongs to the same account
        address account = skinIdToOwner[skinAId];
        require(account == skinIdToOwner[skinBId]);

        // Check these two skins are in the same mixing process
        Skin storage skinA = skins[skinAId];
        Skin storage skinB = skins[skinBId];
        require(skinA.mixingWithId == uint64(skinBId));
        require(skinB.mixingWithId == uint64(skinAId));

        // Check cooldown
        require(_isCooldownReady(skinAId, skinBId));

        // Create new skin
        uint128 newSkinAppearance = mixFormula.calcNewSkinAppearance(skinA.appearance, skinB.appearance);
        Skin memory newSkin = Skin({appearance: newSkinAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = account;
        isOnSale[nextSkinId] = false;
        nextSkinId++;

        // Clear old skins
        skinA.mixingWithId = 0;
        skinB.mixingWithId = 0;

        // In order to distinguish created skins in minting with destroyed skins
        // skinIdToOwner[skinAId] = owner;
        // skinIdToOwner[skinBId] = owner;
        delete skinIdToOwner[skinAId];
        delete skinIdToOwner[skinBId];
        // require(numSkinOfAccounts[account] >= 2);
        numSkinOfAccounts[account] -= 1;

        MixSuccess(account, nextSkinId - 1, skinAId, skinBId);
    }
}
contract SkinMarket is SkinMix {

    // Cut ratio for a transaction
    // Values 0-10,000 map to 0%-100%
    uint128 public trCut = 400;

    // Sale orders list 
    mapping (uint256 => uint256) public desiredPrice;

    // events
    event PutOnSale(address account, uint256 skinId);
    event WithdrawSale(address account, uint256 skinId);
    event BuyInMarket(address buyer, uint256 skinId);

    // functions

    // Put asset on sale
    function putOnSale(uint256 skinId, uint256 price) public whenNotPaused {
        // Only owner of skin pass
        require(skinIdToOwner[skinId] == msg.sender);

        // Check whether skin is mixing 
        require(skins[skinId].mixingWithId == 0);

        // Check whether skin is already on sale
        require(isOnSale[skinId] == false);

        require(price > 0); 

        // Put on sale
        desiredPrice[skinId] = price;
        isOnSale[skinId] = true;

        // Emit the Approval event
        PutOnSale(msg.sender, skinId);
    }
  
    // Withdraw an sale order
    function withdrawSale(uint256 skinId) external whenNotPaused {
        // Check whether this skin is on sale
        require(isOnSale[skinId] == true);
        
        // Can only withdraw self's sale
        require(skinIdToOwner[skinId] == msg.sender);

        // Withdraw
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

        // Emit the cancel event
        WithdrawSale(msg.sender, skinId);
    }
 
    // Buy skin in market
    function buyInMarket(uint256 skinId) external payable whenNotPaused {
        // Check whether this skin is on sale
        require(isOnSale[skinId] == true);

        address seller = skinIdToOwner[skinId];

        // Check the sender isn't the seller
        require(msg.sender != seller);

        uint256 _price = desiredPrice[skinId];
        // Check whether pay value is enough
        require(msg.value >= _price);

        // Cut and then send the proceeds to seller
        uint256 sellerProceeds = _price - _computeCut(_price);

        seller.transfer(sellerProceeds);

        // Transfer skin from seller to buyer
        numSkinOfAccounts[seller] -= 1;
        skinIdToOwner[skinId] = msg.sender;
        numSkinOfAccounts[msg.sender] += 1;
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

        // Emit the buy event
        BuyInMarket(msg.sender, skinId);
    }

    // Compute the marketCut
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * trCut / 10000;
    }
}
contract SkinMinting is SkinMarket {

    // Limits the number of skins the contract owner can ever create.
    uint256 public skinCreatedLimit = 50000;

    // The summon numbers of each accouts: will be cleared every day
    mapping (address => uint256) public accoutToSummonNum;

    // Pay level of each accouts
    mapping (address => uint256) public accoutToPayLevel;
    mapping (address => uint256) public accountsLastClearTime;

    uint256 public levelClearTime = now;

    // price
    uint256 public baseSummonPrice = 3 finney;
    uint256 public bleachPrice = 30 finney;

    // Pay level
    uint256[5] public levelSplits = [10,
                                     20,
                                     50,
                                     100,
                                     200];
    
    uint256[6] public payMultiple = [1,
                                     2,
                                     4,
                                     8,
                                     20,
                                     100];


    // events
    event CreateNewSkin(uint256 skinId, address account);
    event Bleach(uint256 skinId, uint128 newAppearance);

    // functions

    // Set price 
    function setBaseSummonPrice(uint256 newPrice) external onlyOwner {
        baseSummonPrice = newPrice;
    }

    function setBleachPrice(uint256 newPrice) external onlyOwner {
        bleachPrice = newPrice;
    }

    // Create base skin for sell. Only owner can create
    function createSkin(uint128 specifiedAppearance, uint256 salePrice) external onlyOwner whenNotPaused {
        require(numSkinOfAccounts[owner] < skinCreatedLimit);

        // Create specified skin
        // uint128 randomAppearance = mixFormula.randomSkinAppearance();
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = owner;
        isOnSale[nextSkinId] = false;

        // Emit the create event
        CreateNewSkin(nextSkinId, owner);

        // Put this skin on sale
        putOnSale(nextSkinId, salePrice);

        nextSkinId++;
        numSkinOfAccounts[owner] += 1;   
    }

    // Summon
    function summon() external payable whenNotPaused {
        // Clear daily summon numbers
        if (accountsLastClearTime[msg.sender] == uint256(0)) {
            // This account's first time to summon, we do not need to clear summon numbers
            accountsLastClearTime[msg.sender] = now;
        } else {
            if (accountsLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accoutToSummonNum[msg.sender] = 0;
                accoutToPayLevel[msg.sender] = 0;
                accountsLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accoutToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price);

        // Create random skin
        uint128 randomAppearance = mixFormula.randomSkinAppearance();
        // uint128 randomAppearance = 0;
        Skin memory newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

        // Emit the create event
        CreateNewSkin(nextSkinId, msg.sender);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] += 1;
        
        accoutToSummonNum[msg.sender] += 1;
        
        // Handle the paylevel        
        if (payLevel < 5) {
            if (accoutToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accoutToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

    // Bleach some attributes
    function bleach(uint128 skinId, uint128 attributes) external payable whenNotPaused {
        // Check whether msg.sender is owner of the skin 
        require(msg.sender == skinIdToOwner[skinId]);

        // Check whether this skin is on sale 
        require(isOnSale[skinId] == false);

        // Check whether there is enough money
        require(msg.value >= bleachPrice);

        Skin storage originSkin = skins[skinId];
        // Check whether this skin is in mixing 
        require(originSkin.mixingWithId == 0);

        uint128 newAppearance = mixFormula.bleachAppearance(originSkin.appearance, attributes);
        originSkin.appearance = newAppearance;

        // Emit bleach event
        Bleach(skinId, newAppearance);
    }

    // Our daemon will clear daily summon numbers
    function clearSummonNum() external onlyOwner {
        uint256 nextDay = levelClearTime + 1 days;
        if (now > nextDay) {
            levelClearTime = nextDay;
        }
    }
}
