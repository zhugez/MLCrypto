















pragma solidity ^0.6.12;
import "../contracts/modules/common/IModule.sol";
import "../contracts/wallet/IWallet.sol";


contract FakeWallet is IWallet {
    bool targetIsModule;
    address target;
    uint value;
    bytes data;
    constructor(bool _targetIsModule, address _target, uint _value, bytes memory _data) public {
        targetIsModule = _targetIsModule;
        target = _target;
        value = _value;
        data = _data;
    }

    
    address public implementation;
    
    address public override owner;
    
    mapping (address => bool) public override authorised;
    
    mapping (bytes4 => address) public override enabled;
    
    uint public override modules;

    event AuthorisedModule(address indexed module, bool value);
    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);

    
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: msg.sender not an authorized module");
        _;
    }

    
    function init(address _owner, address[] calldata _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: construction requires at least 1 module");
        owner = _owner;
        modules = _modules.length;
        for (uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this));
            emit AuthorisedModule(_modules[i], true);
        }
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }

    
    function authoriseModule(address _module, bool _value) external override moduleOnly {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value == true) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this));
            } else {
                modules -= 1;
                require(modules > 0, "BW: wallet must have at least one module");
                delete authorised[_module];
            }
        }
    }

    
    function enableStaticCall(address _module, bytes4 _method) external override moduleOnly {
        require(authorised[_module], "BW: must be an authorised module for static call");
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }

    
    function setOwner(address _newOwner) external override moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    
    function invoke(address _target, uint _value, bytes calldata _data) external moduleOnly returns (bytes memory _result) {
        if (target != address(0)) {
            address prevOwner = owner;
            if (targetIsModule) {
                
                owner = address(this);
            }

            (bool success,) = target.call{value: value}(data);
            owner = prevOwner;
            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    
    fallback() external payable {
        address module = enabled[msg.sig];
        if (module == address(0)) {
            emit Received(msg.value, msg.sender, msg.data);
        } else {
            require(authorised[module], "BW: must be an authorised module for static call");

            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), module, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }

    receive() external payable {
    }
}