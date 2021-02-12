pragma solidity ^0.6.4;

import "./ItemManager.sol";

contract Item {
    uint public index;
    uint public priceWei;
    uint public paidWei;
    
    ItemManager parentContract;
    
    constructor(ItemManager _parentContract, uint _priceWei, uint _index) public {
        parentContract = _parentContract;
        index = _index;
        priceWei = _priceWei;
    }
    
    receive() external payable {
        require(msg.value >= priceWei, "We don't support partial payments");
        require(paidWei == 0, "Item is already paid!");
        paidWei += msg.value;
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "Delivery did not work");
    }

    fallback () external {

    }
}