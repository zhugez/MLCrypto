
pragma solidity ^0.8.1;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}



library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    
    function toString(uint256 value) internal pure returns (string memory) {
        
        

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenID);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) external view returns (uint256 balance);

    
    function ownerOf(uint256 tokenID) external view returns (address owner);

    
    function safeTransferFrom(address from, address to, uint256 tokenID) external;

    
    function transferFrom(address from, address to, uint256 tokenID) external;

    
    function approve(address to, uint256 tokenID) external;

    
    function getApproved(uint256 tokenID) external view returns (address operator);

    
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) external;
}



abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



interface IERC721Metadata is IERC721 {

    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenID) external view returns (string memory);
}

interface IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenID, bytes calldata data) external returns (bytes4);
}




contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    
    string private _name;

    
    string private _symbol;

    
    mapping (uint256 => address) private _owners;

    
    mapping (address => uint256) private _balances;

    
    mapping (uint256 => address) private _tokenApprovals;

    
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId
        || super.supportsInterface(interfaceId);
    }

    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenID) public view virtual override returns (address) {
        address owner = _owners[tokenID];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenID.toString()))
        : '';
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    function approve(address to, uint256 tokenID) public virtual override {
        address owner = ERC721.ownerOf(tokenID);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenID);
    }

    
    function getApproved(uint256 tokenID) public view virtual override returns (address) {
        require(_exists(tokenID), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenID];
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(address from, address to, uint256 tokenID) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenID);
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
        safeTransferFrom(from, to, tokenID, "");
    }

    
    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenID, _data);
    }

    
    function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
        _transfer(from, to, tokenID);
        require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenID) internal view virtual returns (bool) {
        return _owners[tokenID] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenID) internal view virtual returns (bool) {
        require(_exists(tokenID), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenID);
        return (spender == owner || getApproved(tokenID) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    
    function _safeMint(address to, uint256 tokenID) internal virtual {
        _safeMint(to, tokenID, "");
    }

    
    function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
        _mint(to, tokenID);
        require(_checkOnERC721Received(address(0), to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _mint(address to, uint256 tokenID) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenID), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenID);

        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
    }

    
    function _burn(uint256 tokenID) internal virtual {
        address owner = ERC721.ownerOf(tokenID);

        _beforeTokenTransfer(owner, address(0), tokenID);

        
        _approve(address(0), tokenID);

        _balances[owner] -= 1;
        delete _owners[tokenID];

        emit Transfer(owner, address(0), tokenID);
    }

    
    function _transfer(address from, address to, uint256 tokenID) internal virtual {
        require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenID);

        
        _approve(address(0), tokenID);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(from, to, tokenID);
    }

    
    function _approve(address to, uint256 tokenID) internal virtual {
        _tokenApprovals[tokenID] = to;
        emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
    }

    
    function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data)
    private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenID, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    
    function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual { }
}

abstract contract AccessControl is Context {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


contract MinterAccess is Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, _msgSender()), "MinterAccess: Sender is not a minter");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function addMinter(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinter(address account) external {
        renounceRole(MINTER_ROLE, account);
    }

    function revokeMinter(address account) external {
        revokeRole(MINTER_ROLE, account);
    }
}


contract DMarketNFTToken is MinterAccess, ERC721 {

    
    string private _baseTokenURI;

    constructor (address newOwner, string memory tokenURIPrefix) ERC721("DMarket NFT Swap", "DM NFT") {
        transferOwnership(newOwner);
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _baseTokenURI = tokenURIPrefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function burn(uint256 tokenID) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "DMarketNFTToken: caller is not owner nor approved");
        _burn(tokenID);
    }


    function mintToken(address to, uint64 tokenID) public virtual onlyMinter {
        _mint(to, tokenID);
    }

    function mintTokenBatch(address[] memory receivers, uint64[] memory tokenIDs) public virtual onlyMinter {
        require(receivers.length > 0,"DMarketNFTToken: must be some receivers");
        require(receivers.length == tokenIDs.length, "DMarketNFTToken: must be the same number of receivers/tokenIDs");

        for (uint64 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 tokenID = tokenIDs[i];
            _mint(to, tokenID);
        }
    }

}