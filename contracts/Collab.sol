// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./HasSecondarySaleFees.sol";


contract PFNFT is ERC721Enumerable, Ownable, HasSecondarySaleFees{
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 1 ether;
  uint256 public winRate = 5;
  uint256 public maxSupply = 10;
  uint256 public maxMintAmount = 1;
  uint256 public nftPerAddressLimit = 20;
  uint256 private seed; //seed used to randomize winner
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  address payable[2] royaltyRecipients;
  mapping(address => uint256) public addressMintedBalance;

  //Emit event to send out winning  
  event WinningMint(address sender, uint256 prize);
  event MintedNFT(address sender, uint256 mintAmount);
  //Emit event on royalty Epor.io
  event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);


  constructor(string memory _name, string memory _symbol, string memory _initBaseURI, string memory _initNotRevealedUri, address payable[2] memory _royaltyRecipients) 
    ERC721(_name, _symbol) 
    HasSecondarySaleFees(new address payable[](0), new uint256[](0)) payable {
    require(_royaltyRecipients[0] != address(0), "Invalid address");
    require(_royaltyRecipients[1] != address(0), "Invalid address");
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    
    royaltyRecipients = _royaltyRecipients;
    
    address payable[] memory thisAddressInArray = new address payable[](1);
    thisAddressInArray[0] = payable(address(this));
    uint256[] memory royaltyWithTwoDecimals = new uint256[](1);
    royaltyWithTwoDecimals[0] = 500;

    _setCommonRoyalties(thisAddressInArray, royaltyWithTwoDecimals);
  }
  
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, HasSecondarySaleFees)
    returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) ||
        HasSecondarySaleFees.supportsInterface(interfaceId);
    }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);

      /*----adding in random reward system -----*/
      uint256 randomNumber = (block.difficulty + block.timestamp + seed) % 100;
      seed = randomNumber;
         if (msg.sender != owner()) {
            if (randomNumber < winRate) {
                require(cost <= address(this).balance, "Trying to withdraw more money than they contract has.");
                (bool success, ) = (msg.sender).call{value: cost}("");
                require(success, "Failed to withdraw money from contract.");

                //emit event of winning
                emit WinningMint(msg.sender, cost);
            }
        
        }
      /* ----------------------------*/
      
    }
    //Emit event that Mint Job has minted the NFT
    emit MintedNFT(msg.sender, _mintAmount);
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }


  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setWinRate(uint256 _newRate) public onlyOwner() {
    winRate = _newRate;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  //pass in an array of type function not memory but calldata
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}