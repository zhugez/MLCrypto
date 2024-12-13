














pragma solidity ^0.5.4;
import "./SafeMath.sol";
import "./BaseWallet.sol";
import "./ModuleRegistry.sol";
import "./GuardianStorage.sol";
import "./Module.sol";


contract BaseModule is Module {

    
    bytes constant internal EMPTY_BYTES = "";

    
    ModuleRegistry internal registry;
    
    GuardianStorage internal guardianStorage;

    
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
        verifyUnlocked(_wallet);
        _;
    }

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, GuardianStorage _guardianStorage, bytes32 _name) public {
        registry = _registry;
        guardianStorage = _guardianStorage;
        emit ModuleCreated(_name);
    }

    
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

    
    modifier onlyWalletOwner(BaseWallet _wallet) {
        
        verifyWalletOwner(_wallet);
        _;
    }

    
    modifier strictOnlyWalletOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

    
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        emit ModuleInitialised(address(_wallet));
    }

    
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

    
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        bool success = ERC20(_token).transfer(address(registry), total);
        require(success, "BM: recover token transfer failed");
    }

    
    function verifyUnlocked(BaseWallet _wallet) internal view {
        require(!guardianStorage.isLocked(_wallet), "BM: wallet locked");
    }

     
    function verifyWalletOwner(BaseWallet _wallet) internal view {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be wallet owner");
    }

    
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }

    
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory _res) {
        bool success;
        
        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if (success && _res.length > 0) { 
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
            
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        } else if (!success) {
            revert("BM: wallet invoke reverted");
        }
    }
}