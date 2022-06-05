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
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("Tyler Token", "TMT") {
    // owner of contract is the one deploying it
        owner = payable(msg.sender);
    }
    // payable allows function to recieve ether
    // updates listing price
    function updateroyaltyPrice(uint _royaltyPrice) public payable {
        require(owner == msg.sender, "Only listing owner can update the listing price");

        royaltyPrice = _royaltyPrice;
    }
    // view means function only returns something
    function getroyaltyPrice() public view returns (uint256) {
        return royaltyPrice;
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
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == royaltyPrice, "Price must be equal to the listing price");
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
        emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        false
      );
    }
    // Relist token
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");
        require(msg.value == royaltyPrice, "Price must be equal to the listing price");
        // Update properties of NFT
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }
    // Create sale
    function createMarketSale(uint256 tokenId) public payable {
        uint price = idToMarketItem[tokenId].price;

        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        // Update properties of NFT
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        // Send royalty to marketplace owner
        payable(owner).transfer(royaltyPrice);
        // Send eth to seller
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }
    // Returns all unsold items belonging to marketplace
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex= 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for(uint i = 0; i < itemCount; i++) {
            // Check whether item is unsold
            if(idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        // Find how many NFTs user owns
        for(uint i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {
            // Check whether item is unsold
            if(idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }
    // List specific wallet's for sale NFTs
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        // Find how many NFTs user is selling
        for(uint i = 0; i < totalItemCount; i++) {
            if(idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < totalItemCount; i++) {
            // Check whether item is unsold
            if(idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;

                MarketItem storage currentItem = idToMarketItem[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }
}
