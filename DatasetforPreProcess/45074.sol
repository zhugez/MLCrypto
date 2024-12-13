














pragma solidity ^0.5.4;

import "./common/BaseModule.sol";
import "./common/RelayerModule.sol";
import "./common/OnlyOwnerModule.sol";


contract NftTransfer is BaseModule, RelayerModule, OnlyOwnerModule {

    bytes32 constant NAME = "NftTransfer";

    
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    
    address public ckAddress;

    

    event NonFungibleTransfer(address indexed wallet, address indexed nftContract, uint256 indexed tokenId, address to, bytes data);

    

    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        address _ckAddress
    )
        BaseModule(_registry, _guardianStorage, NAME)
        public
    {
        ckAddress = _ckAddress;
    }

    

    
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        _wallet.enableStaticCall(address(this), ERC721_RECEIVED);
    }

    
    function onERC721Received(
        address ,
        address ,
        uint256 ,
        bytes calldata 
    )
        external
        returns (bytes4)
    {
        return ERC721_RECEIVED;
    }

    
    function transferNFT(
        BaseWallet _wallet,
        address _nftContract,
        address _to,
        uint256 _tokenId,
        bool _safe,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        bytes memory methodData;
        if (_nftContract == ckAddress) {
            methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _tokenId);
        } else {
           if (_safe) {
               methodData = abi.encodeWithSignature(
                   "safeTransferFrom(address,address,uint256,bytes)", address(_wallet), _to, _tokenId, _data);
           } else {
               require(isERC721(_nftContract, _tokenId), "NT: Non-compliant NFT contract");
               methodData = abi.encodeWithSignature(
                   "transferFrom(address,address,uint256)", address(_wallet), _to, _tokenId);
           }
        }
        invokeWallet(address(_wallet), _nftContract, 0, methodData);
        emit NonFungibleTransfer(address(_wallet), _nftContract, _tokenId, _to, _data);
    }

    

    
    function isERC721(address _nftContract, uint256 _tokenId) internal returns (bool) {
        
        (bool success, bytes memory result) = _nftContract.call(abi.encodeWithSignature("supportsInterface(bytes4)", 0x80ac58cd));
        if (success && result[0] != 0x0)
            return true;

        
        (success, result) = _nftContract.call(abi.encodeWithSignature("supportsInterface(bytes4)", 0x6466353c));
        if (success && result[0] != 0x0)
            return true;

        
        (success,) = _nftContract.call(abi.encodeWithSignature("ownerOf(uint256)", _tokenId));
        return success;
    }

}