















pragma solidity ^0.6.12;

import "../wallet/Proxy.sol";
import "../wallet/BaseWallet.sol";
import "./base/Managed.sol";
import "./storage/IGuardianStorage.sol";
import "../modules/common/Utils.sol";


contract WalletFactory is Managed {

    address constant internal ETH_TOKEN = address(0);

    
    address public walletImplementation;
    
    address public guardianStorage;
    
    address public refundAddress; 

    

    event RefundAddressChanged(address addr);
    event WalletCreated(address indexed wallet, address indexed owner, address indexed guardian, address refundToken, uint256 refundAmount);

    

    
    constructor(address _walletImplementation, address _guardianStorage, address _refundAddress) public {
        
        require(_walletImplementation != address(0), "WF: empty wallet implementation");
        require(_guardianStorage != address(0), "WF: empty guardian storage");
        require(_refundAddress != address(0), "WF: empty refund address");
        walletImplementation = _walletImplementation;
        guardianStorage = _guardianStorage;
        refundAddress = _refundAddress;
    }

    

    
    function revokeManager(address ) override external {
        revert("WF: managers can't be revoked");
    }
     
    
    function createCounterfactualWallet(
        address _owner,
        address[] calldata _modules,
        address _guardian,
        bytes20 _salt,
        uint256 _refundAmount,
        address _refundToken,
        bytes calldata _ownerSignature,
        bytes calldata _managerSignature
    )
        external
        returns (address _wallet)
    {
        validateInputs(_owner, _modules, _guardian);
        bytes32 newsalt = newSalt(_salt, _owner, _modules, _guardian);
        address payable wallet = address(new Proxy{salt: newsalt}(walletImplementation));
        validateAuthorisedCreation(wallet, _managerSignature);
        configureWallet(BaseWallet(wallet), _owner, _modules, _guardian);
        if (_refundAmount > 0 && _ownerSignature.length == 65) {
            validateAndRefund(wallet, _owner, _refundAmount, _refundToken, _ownerSignature);
        }
        
        BaseWallet(wallet).authoriseModule(address(this), false);

        
        emit WalletCreated(wallet, _owner, _guardian, _refundToken, _refundAmount);

        return wallet;
    }

    
    function getAddressForCounterfactualWallet(
        address _owner,
        address[] calldata _modules,
        address _guardian,
        bytes20 _salt
    )
        external
        view
        returns (address _wallet)
    {
        validateInputs(_owner, _modules, _guardian);
        bytes32 newsalt = newSalt(_salt, _owner, _modules, _guardian);
        bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint256(walletImplementation));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), newsalt, keccak256(code)));
        _wallet = address(uint160(uint256(hash)));
    }

    
    function changeRefundAddress(address _refundAddress) external onlyOwner {
        require(_refundAddress != address(0), "WF: cannot set to empty");
        refundAddress = _refundAddress;
        emit RefundAddressChanged(_refundAddress);
    }

    
    function init(BaseWallet _wallet) external pure {
        
    }

    

    
    function configureWallet(BaseWallet _wallet, address _owner, address[] calldata _modules, address _guardian) internal {
        
        address[] memory extendedModules = new address[](_modules.length + 1);
        extendedModules[0] = address(this);
        for (uint i = 0; i < _modules.length; i++) {
            extendedModules[i + 1] = _modules[i];
        }

        
        _wallet.init(_owner, extendedModules);

        
        IGuardianStorage(guardianStorage).addGuardian(address(_wallet), _guardian);
    }

    
    function newSalt(bytes20 _salt, address _owner, address[] calldata _modules, address _guardian) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(_owner, _modules, _guardian)), _salt));
    }

    
    function validateInputs(address _owner, address[] calldata _modules, address _guardian) internal pure {
        require(_owner != address(0), "WF: empty owner address");
        require(_owner != _guardian, "WF: owner cannot be guardian");
        require(_modules.length > 0, "WF: empty modules");
        require(_guardian != (address(0)), "WF: empty guardian");        
    }

    
    function validateAuthorisedCreation(address _wallet, bytes memory _managerSignature) internal view {
        address manager;
        if(_managerSignature.length != 65) {
            manager = msg.sender;
        } else {
            bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", bytes32(uint256(_wallet))));
            manager = Utils.recoverSigner(signedHash, _managerSignature, 0);
        }
        require(managers[manager], "WF: unauthorised wallet creation");
    }

    
    function validateAndRefund(
        address _wallet,
        address _owner,
        uint256 _refundAmount,
        address _refundToken,
        bytes memory _ownerSignature
    )
        internal
    {
        bytes32 signedHash = keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_refundAmount, _refundToken))
            ));
        address signer = Utils.recoverSigner(signedHash, _ownerSignature, 0);
        if (signer == _owner) {
            if (_refundToken == ETH_TOKEN) {
                invokeWallet(_wallet, refundAddress, _refundAmount, "");
            } else {
                bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", refundAddress, _refundAmount);
                bytes memory transferSuccessBytes = invokeWallet(_wallet, _refundToken, 0, methodData);
                if (transferSuccessBytes.length > 0) {
                    require(abi.decode(transferSuccessBytes, (bool)), "WF: Refund transfer failed");
                }
            }
        }
    }

    
    function invokeWallet(
        address _wallet,
        address _to,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns (bytes memory _res)
    {
        bool success;
        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if (success) {
            (_res) = abi.decode(_res, (bytes));
        } else {
            
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
