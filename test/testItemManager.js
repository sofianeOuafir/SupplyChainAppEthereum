const ItemManager = artifacts.require('./ItemManager.sol');

contract("ItemManager", async (accounts) => {
  it("should be able to add an item", async () => {
    let instance = await ItemManager.deployed();
    let result = await instance.createItem("Phone", "1000", { from: accounts[0] });
    console.log(result);
    assert.equal(result.logs[0].args._index, 0, "it's not the first item");
    
    const item = await instance.items(0);
    assert.equal(item._identifier, "Phone", "it's not working");
  })
})