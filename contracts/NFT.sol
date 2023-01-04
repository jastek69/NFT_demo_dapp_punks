// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {  // inheritance - inherits from the parent ERC 721 contract
    using Strings for uint256; // needed to make toString to work with Solidity

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public allowMintingOn;    

    event Mint(uint256 amount, address minter);
    event Withdraw(uint256 amount, address owner);
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _allowMintingOn,
        string memory _baseURI
    ) ERC721(_name, _symbol) { // Calls the contructor function of the Parent ERC721
        cost = _cost;
        maxSupply = _maxSupply;
        allowMintingOn = _allowMintingOn;
        baseURI = _baseURI;
    }

    function mint(uint256 _mintAmount) public payable {     // payable allows receiving of currency
        // Only allow minting after a specified time
       require(block.timestamp >= allowMintingOn, "Must wait until allow minting on");

        //Require they mint some tokens. Must mint at least 1 token
        require(_mintAmount > 0, "Must mint at least 1");

        //Require enough payment
        require(msg.value >= cost * _mintAmount, "msg.value must be at least cost");
        
        uint256 supply = totalSupply();     // get total supply from ERC721Enumerable

        // Do not permit minting of more tokens than supply
        require(supply + _mintAmount <= maxSupply, "CAn not exceeed max supply");

        // Create tokens
        for(uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);  // call from ERC721.sol
        }

        // Emit event
        emit Mint(_mintAmount, msg.sender);        
    }

    // Return metadata IPFS url
    //E.G.: 'ipfs://QmQ2jnDYecFhrf3asEWjyjZRX1pZSsNWG3qHzmNDvXa9qg/'
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns(string memory)
    {
        require(_exists(_tokenId), 'token does not exist');      
        return(string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension)));        
    }

    // Display all NFTs owner has
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for(uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds; // retunrs all of the Ids the owner has
    }

    // Owner functions
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success);

        emit Withdraw(balance, msg.sender);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
}
