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
    uint256 listingPrice = 0.025 ether;

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
    function updateListingPrice(uint _listingPrice) public payable {
        require(owner == msg.sender, "Only listing owner can update the listing price");

        listingPrice = _listingPrice;
    }
    // view means function only returns something
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // Upload NFT and get token URI
    function createToken(string memory tokenURI, uint256 price) public payable returns (uint) {
        _tokenIds.increment();
        // Create variable that gets current value of token ids
        uint256 newTokenId = _tokenIds.current();
        // Mint token
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        // Take minted token and list to marketplace
        createMarketItem(newTokenId, price);
         
        return newTokenId;
    }
    // Private functions are not called from frontend
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1");
        require(msg.value == listingPrice, "Price must be equal to the listing price");
        // Create mapping for market items
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        // Transfer ownership to contract
        _transfer(msg.sender, address(this), tokenId);
        // Broadcast event to blockchain
        emit MarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }

    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        require(msg.value == listingPrice, "Price must be equal to the listing price");
        // Update properties of NFT
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }
}
