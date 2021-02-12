pragma solidity ^0.6.0;

import "./Item.sol";
import "./Ownable.sol";

contract ItemManager is Ownable {
    enum SupplyChainSteps{ Created, Paid, Delivered } 
    
    struct S_Item {
        Item _item;
        ItemManager.SupplyChainSteps _step;
        string _identifier;
    }
    
    mapping(uint => S_Item) public items;
    
    uint index;
    
    event SupplyChainStep(uint _index, uint _step, address _address); 
    
    function createItem(string memory _identifier, uint _priceWei) public onlyOwner {
        Item item = new Item(this, _priceWei, index);
        items[index]._item = item;
        items[index]._step = SupplyChainSteps.Created;
        items[index]._identifier = _identifier;
        emit SupplyChainStep(index, uint(items[index]._step), address(items[index]._item));
        index++;
    }
    
    function triggerPayment(uint _index) public payable {
        Item item = items[_index]._item;
        require(address(item) == msg.sender, "Only items are allowed to update themselves");
        require(msg.value >= item.priceWei(), "Not enough money sent.");
        require(items[_index]._step == SupplyChainSteps.Created, "Item has already been paid.");
        items[_index]._step = SupplyChainSteps.Paid;
        emit SupplyChainStep(_index, uint(items[_index]._step), address(item));
    }
    
    function triggerDelivery(uint _index) public onlyOwner {
        require(items[_index]._step != SupplyChainSteps.Delivered, "Item has already been delivered");
        require(items[_index]._step == SupplyChainSteps.Paid, "Item has not been paid");
        items[_index]._step = SupplyChainSteps.Delivered;
        emit SupplyChainStep(_index, uint(items[_index]._step), address(items[_index]._item));
    }
}