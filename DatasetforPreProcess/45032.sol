














pragma solidity ^0.5.4;
import "../wallet/BaseWallet.sol";
import "./common/GuardianUtils.sol";
import "./common/BaseModule.sol";
import "./common/RelayerModule.sol";


contract GuardianManager is BaseModule, RelayerModule {

    bytes32 constant NAME = "GuardianManager";

    bytes4 constant internal CONFIRM_ADDITION_PREFIX = bytes4(keccak256("confirmGuardianAddition(address,address)"));
    bytes4 constant internal CONFIRM_REVOKATION_PREFIX = bytes4(keccak256("confirmGuardianRevokation(address,address)"));

    struct GuardianManagerConfig {
        
        mapping (bytes32 => uint256) pending;
    }

    
    mapping (address => GuardianManagerConfig) internal configs;
    
    uint256 public securityPeriod;
    
    uint256 public securityWindow;

    

    event GuardianAdditionRequested(address indexed wallet, address indexed guardian, uint256 executeAfter);
    event GuardianRevokationRequested(address indexed wallet, address indexed guardian, uint256 executeAfter);
    event GuardianAdditionCancelled(address indexed wallet, address indexed guardian);
    event GuardianRevokationCancelled(address indexed wallet, address indexed guardian);
    event GuardianAdded(address indexed wallet, address indexed guardian);
    event GuardianRevoked(address indexed wallet, address indexed guardian);

    

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        uint256 _securityPeriod,
        uint256 _securityWindow
    )
        BaseModule(_registry, _guardianStorage, NAME)
        public
    {
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
    }

    

    
    function addGuardian(BaseWallet _wallet, address _guardian) external onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        require(!isOwner(_wallet, _guardian), "GM: target guardian cannot be owner");
        require(!isGuardian(_wallet, _guardian), "GM: target is already a guardian");
        
        
        
        
        (bool success,) = _guardian.call.gas(5000)(abi.encodeWithSignature("owner()"));
        require(success, "GM: guardian must be EOA or implement owner()");
        if (guardianStorage.guardianCount(_wallet) == 0) {
            guardianStorage.addGuardian(_wallet, _guardian);
            emit GuardianAdded(address(_wallet), _guardian);
        } else {
            bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "addition"));
            GuardianManagerConfig storage config = configs[address(_wallet)];
            require(
                config.pending[id] == 0 || now > config.pending[id] + securityWindow,
                "GM: addition of target as guardian is already pending");
            config.pending[id] = now + securityPeriod;
            emit GuardianAdditionRequested(address(_wallet), _guardian, now + securityPeriod);
        }
    }

    
    function confirmGuardianAddition(BaseWallet _wallet, address _guardian) public onlyWhenUnlocked(_wallet) {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "addition"));
        GuardianManagerConfig storage config = configs[address(_wallet)];
        require(config.pending[id] > 0, "GM: no pending addition as guardian for target");
        require(config.pending[id] < now, "GM: Too early to confirm guardian addition");
        require(now < config.pending[id] + securityWindow, "GM: Too late to confirm guardian addition");
        guardianStorage.addGuardian(_wallet, _guardian);
        delete config.pending[id];
        emit GuardianAdded(address(_wallet), _guardian);
    }

    
    function cancelGuardianAddition(BaseWallet _wallet, address _guardian) public onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "addition"));
        GuardianManagerConfig storage config = configs[address(_wallet)];
        require(config.pending[id] > 0, "GM: no pending addition as guardian for target");
        delete config.pending[id];
        emit GuardianAdditionCancelled(address(_wallet), _guardian);
    }

    
    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyWalletOwner(_wallet) {
        require(isGuardian(_wallet, _guardian), "GM: must be an existing guardian");
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "revokation"));
        GuardianManagerConfig storage config = configs[address(_wallet)];
        require(
            config.pending[id] == 0 || now > config.pending[id] + securityWindow,
            "GM: revokation of target as guardian is already pending"); 
        config.pending[id] = now + securityPeriod;
        emit GuardianRevokationRequested(address(_wallet), _guardian, now + securityPeriod);
    }

    
    function confirmGuardianRevokation(BaseWallet _wallet, address _guardian) public {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "revokation"));
        GuardianManagerConfig storage config = configs[address(_wallet)];
        require(config.pending[id] > 0, "GM: no pending guardian revokation for target");
        require(config.pending[id] < now, "GM: Too early to confirm guardian revokation");
        require(now < config.pending[id] + securityWindow, "GM: Too late to confirm guardian revokation");
        guardianStorage.revokeGuardian(_wallet, _guardian);
        delete config.pending[id];
        emit GuardianRevoked(address(_wallet), _guardian);
    }

    
    function cancelGuardianRevokation(BaseWallet _wallet, address _guardian) public onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _guardian, "revokation"));
        GuardianManagerConfig storage config = configs[address(_wallet)];
        require(config.pending[id] > 0, "GM: no pending guardian revokation for target");
        delete config.pending[id];
        emit GuardianRevokationCancelled(address(_wallet), _guardian);
    }

    
    function isGuardian(BaseWallet _wallet, address _guardian) public view returns (bool _isGuardian) {
        (_isGuardian, ) = GuardianUtils.isGuardian(guardianStorage.getGuardians(_wallet), _guardian);
    }

    
    function guardianCount(BaseWallet _wallet) external view returns (uint256 _count) {
        return guardianStorage.guardianCount(_wallet);
    }

    

    
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 ) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(
        BaseWallet _wallet,
        bytes memory ,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal
        view
        returns (bool)
    {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer); 
    }

    function getRequiredSignatures(BaseWallet , bytes memory _data) internal view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == CONFIRM_ADDITION_PREFIX || methodId == CONFIRM_REVOKATION_PREFIX) {
            return 0;
        }
        return 1;
    }
}