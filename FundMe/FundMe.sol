// get funds from users
// withdraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address public immutable i_owner;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        // Want to be able ot set a minimum funds amount in USD
        // 1. How do we send ETH to this contract?
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough"); // 1e18 == 1 * 10 ** 18 = 10000...
        // What is reverting?
        // undo any action before, and send remaining gas back (but also we are spending gas!!!)
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        for(uint256 i = 0; i < funders.length; i++) {
            // reseting back to 0 all the funders
            addressToAmountFunded[funders[i]] = 0;
        }
        // reset the array
        funders = new address[](0);
        // actually withdraw the funds

        // three options: https://solidity-by-example.org/sending-ether
        // TRASNFER: throw error
        // payable(msg.sender).transfer(address(this).balance);
        // SEND: returns bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call: most base
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "You arn't the owner");
        if (msg.sender != i_owner) { revert NotOwner(); }
        _; // indicates where is executed the function code (before or after this line)
    }

    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }
}