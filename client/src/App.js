import React, { Component } from "react";
import ItemManager from "./contracts/ItemManager.json";
import Item from "./contracts/Item.json";
import getWeb3 from "./getWeb3";

import "./App.css";

const steps = {
  0: "Created",
  1: "Paid",
  2: "Delivered",
};

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      cost: 0,
      itemName: "exampleItem1",
      loaded: false,
      items: [],
    };
  }

  addItem = (item) => {
    this.setState((state) => {
      const items = [...state.items, item];

      return { items };
    });
  };

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      this.web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      this.accounts = await this.web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await this.web3.eth.net.getId();
      this.itemManager = new this.web3.eth.Contract(
        ItemManager.abi,
        ItemManager.networks[networkId] &&
          ItemManager.networks[networkId].address
      );
      this.item = new this.web3.eth.Contract(
        Item.abi,
        Item.networks[networkId] && Item.networks[networkId].address
      );

      const index = await this.itemManager.methods.index().call();
      if (index) {
        for (let i = 0; i < index; i++) {
          const item = await this.itemManager.methods.items(i).call();
          console.log("hey", item);
          const itemToAdd = {
            identifier: item._identifier,
            price: item._priceWei,
            address: item[0],
            step: item._step,
          };
          this.addItem(itemToAdd);
        }
      }
      this.listenToPaymentEvent();
      this.setState({ loaded: true });
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.error(error);
    }
  };

  handleSubmit = async (e) => {
    e.preventDefault();
    const { cost, itemName } = this.state;
    console.log("creating item", itemName, cost, this.itemManager);
    let result = await this.itemManager.methods
      .createItem(itemName, cost)
      .send({ from: this.accounts[0] });
    console.log("yo", result);
    const item = await this.itemManager.methods
      .items(result.events.SupplyChainStep.returnValues._index)
      .call();
    this.addItem({
      identifier: item._identifier,
      price: item._priceWei,
      address: item[0],
      step: item._step,
    });
    alert(
      "Send " +
        cost +
        " Wei to " +
        result.events.SupplyChainStep.returnValues._address
    );
  };

  listenToPaymentEvent = () => {
    let self = this;
    this.itemManager.events.SupplyChainStep().on("data", async function (evt) {
      if (evt.returnValues._step == 1) {
        console.log(evt.returnValues);
        let item = await self.itemManager.methods
          .items(evt.returnValues._index)
          .call();
        self.setState((state) => {
          const items = state.items.map((it) => {
            if (it.identifier == item._identifier) {
              return {
                ...it,
                step: 1,
              };
            } else {
              return it;
            }
          });

          return { items };
        });
        console.log(item);
        alert("Item " + item._identifier + " was paid, deliver it now!");
      }
      console.log(evt);
    });
  };

  handleInputChange = (event) => {
    const target = event.target;
    const value = target.type === "checkbox" ? target.checked : target.value;
    const name = target.name;

    this.setState({
      [name]: value,
    });
  };

  render() {
    if (!this.state.loaded) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <h1>Simply Payment/Supply Chain Example!</h1>
        <h2>Items</h2>
        <h2>Add Element</h2>
        Cost:{" "}
        <input
          type="text"
          name="cost"
          value={this.state.cost}
          onChange={this.handleInputChange}
        />
        Item Name:{" "}
        <input
          type="text"
          name="itemName"
          value={this.state.itemName}
          onChange={this.handleInputChange}
        />
        <button type="button" onClick={this.handleSubmit}>
          Create new Item
        </button>
        <ul>
          {this.state.items.map((item) => {
            return (
              <li>
                Identifier: {item.identifier} - Price (wei): {item.price} -
                Address: {item.address} - Status: {steps[item.step]}
              </li>
            );
          })}
        </ul>
      </div>
    );
  }
}

export default App;
