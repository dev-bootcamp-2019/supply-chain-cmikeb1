pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {

    // Test for failing conditions in this contracts
    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());

    // Truffle will send the TestContract one Ether after deploying the contract.
    uint public initialBalance = 1 ether;

    function testCanListItem() public {
        uint itemPrice = .1 ether;
        string memory itemName = "firstItem";

        supplyChain.addItem(itemName, itemPrice);

        (string memory name,
        uint sku,
        uint price,
        uint state,
        address seller,
        address buyer) = supplyChain.fetchItem(0);

        Assert.equal(sku, 0, "Incorrect sku on added item.");
        Assert.equal(name, itemName, "Incorrect name on added item.");
        Assert.equal(price, itemPrice, "Incorrect price on added item.");
        Assert.equal(state, 0, "Incorrect state on added item.");
        Assert.equal(seller, address(this), "Incorrect seller on added item.");
        Assert.equal(buyer, address(0), "Incorrect buyer on added item.");
    }

    function testSecondListedItemSkuIncrementsByOne() public {
        uint itemPrice = .2 ether;
        string memory itemName = "secondItem";

        supplyChain.addItem(itemName, itemPrice);

        (string memory name,
        uint sku,
        uint price,
        uint state,
        address seller,
        address buyer) = supplyChain.fetchItem(1);

        Assert.equal(name, itemName, "Incorrect name");
        Assert.equal(sku, 1, "Incorrect sku");
    }


    function testModifierForSale_unlistedFails() public {
        uint itemPrice = 100;

        RevertWrapper revertWrapper = new RevertWrapper(address(supplyChain));

        SupplyChain(address(revertWrapper)).buyItem.value(150)(0);

        bool r = revertWrapper.execute.gas(200000)();

        Assert.isFalse(r, "Selling should fail if item is not listed.");
    }

    function testModifierForSale_soldCannotBeSold() public {
        uint itemPrice = 100;
        string memory itemName = "itemname";

        supplyChain.addItem(itemName, itemPrice);

        RevertWrapper revertWrapper = new RevertWrapper(address(supplyChain));

        SupplyChain(address(revertWrapper)).buyItem.value(150)(0);

        bool r = revertWrapper.execute.gas(200000)();

        Assert.isFalse(r, "Selling should fail if item is not listed.");
    }
}

contract RevertWrapper {
    address public target;
    bytes data;

    constructor (address _target) public {
        target = _target;
    }

    function() public payable {
        data = msg.data;
    }

    function execute() public payable returns (bool) {
        return target.call(data);
    }
}