//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract MaggiosMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    // create token ids
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    // set royalty price
    uint256 royaltyPrice = 0.025 ether;

    // declare owner of contract - owner gets commission
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;
    // structs are like JS objects
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    // event triggered on an action
    event MarketItemCreated (
        uint256 indexed tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    constructor() {
    // owner of contract is the one deploying it
        owner = payable(msg.sender);
    }
    // payable allows function to recieve ether
    // updates listing price
    function updateListingPrice(uint _royaltyPrice) public payable {
        require(owner == msg.sender, "Only listing owner can update the listing price");

        royaltyPrice = _royaltyPrice;
    }
    // view means function only returns something
    function getListingPrice() public view returns (uint256) {
        return royaltyPrice;
    }
}
