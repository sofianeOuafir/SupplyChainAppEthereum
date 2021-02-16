pragma solidity ^0.6.0;

import "./Item.sol";
import "./Ownable.sol";

contract ItemManager is Ownable {
    enum SupplyChainSteps{ Created, Paid, Delivered } 
    
    struct S_Item {
        Item _item;
        ItemManager.SupplyChainSteps _step;
        string _identifier;
        uint _priceWei;
    }
    
    mapping(uint => S_Item) public items;
    
    uint public index;
    
    event SupplyChainStep(uint _index, uint _step, address _address); 
    
    function createItem(string memory _identifier, uint _priceWei) public onlyOwner {
        Item item = new Item(this, _priceWei, index);
        items[index]._item = item;
        items[index]._step = SupplyChainSteps.Created;
        items[index]._identifier = _identifier;
        items[index]._priceWei = _priceWei;
        emit SupplyChainStep(index, uint(items[index]._step), address(items[index]._item));
        index++;
    }

    // function SeeAllItems() public view returns(uint[] memory) {
    //     uint[] memory prices = new uint[](index);
    //     string[] memory identifiers = new string[](index);
    //     for(uint i = 0; i < index; i++) {
    //         prices[i] = items[i]._item.priceWei;
    //         identifiers[i] = items[i]._identifier;
    //     }
    //     return prices;
    // }

    // function getAll() public view returns (uint[] memory){
    //     uint[] memory ret = new uint[](index);
    //     for (uint i = 0; i < index; i++) {
    //         ret[i] = items[i]._item.priceWei;
    //     }
    //     return ret;
    // }
    
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