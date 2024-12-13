pragma solidity ^0.5.0;

import { ERC1155TokenReceiver } from "../contracts/ERC1155/ERC1155TokenReceiver.sol";

contract Forwarder is ERC1155TokenReceiver {
    function call(address to, bytes calldata data) external {
        (bool success, bytes memory retData) = to.call(data);
        require(success, string(retData));
    }

    function onERC1155Received(
        address ,
        address ,
        uint256 ,
        uint256 ,
        bytes calldata 
    )
        external
        returns(bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata ,
        uint256[] calldata ,
        bytes calldata 
    )
        external
        returns(bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}
