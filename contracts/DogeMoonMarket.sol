// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IDogeMoonMarket.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./utils/Context.sol";
import "./utils/SafeMath.sol";

contract DogeMoonMarket is Context, IDogeMoonMarket, IERC721Receiver{
    using SafeMath for uint;
    modifier onlyOwner{
        require(_msgSender() == _owner, "Only owner can process");
        _;
    }
    
    struct MarketHistory{
        address buyer;
        address seller;
        uint256 price;
        uint256 time;
    }
    
     //Contract owner
    address private _owner;
    
    address private _dogeMoonTokenAddress;
    address private _dogeMoonNftAddress;
    
    uint256 private _feePercent;       //Multipled by 10
    
    uint256[] internal _tokens;
    
    //Mapping between tokenId and token price
    mapping(uint256 => uint256) internal _tokenPrices;
    
    //Mapping between tokenId and owner of tokenId
    mapping(uint256 => address) internal _tokenOwners;
    
    mapping(uint256 => MarketHistory[]) internal _marketHistories;
    
    constructor(){
        _dogeMoonTokenAddress = 0x69075f3190222c7163925CE0D3C3d7f1499d2f57;
        _dogeMoonNftAddress = 0x3c70a7413A996370990Fb9c68DAc893Dd356357d;
        _owner = _msgSender();
        _feePercent = 1;        //0.1%
    }
    
    /**
     * @dev Create a sell order to sell DOGEMOON category
     */
    function createSellOrder(uint256 tokenId, uint256 price) external override returns(bool){
        //Validate
        require(_tokenOwners[tokenId] == address(0), "Can not create sell order for this token");
        IERC721 dogeMoonContract = IERC721(_dogeMoonNftAddress);
        require(dogeMoonContract.ownerOf(tokenId) == _msgSender(), "You have no permission to create sell order for this token");
        
        //Transfer DogeMoon NFT to contract
        dogeMoonContract.safeTransferFrom(_msgSender(), address(this), tokenId);
        
        _tokenOwners[tokenId] = _msgSender();
        _tokenPrices[tokenId] = price;
        _tokens.push(tokenId);
        
        emit NewSellOrderCreated(_msgSender(), tokenId, price);
        
        return true;
    }
    
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external override returns(bool){
        require(_tokenOwners[tokenId] == _msgSender(), "Forbidden to cancel sell order");

        IERC721 dogeMoonContract = IERC721(_dogeMoonNftAddress);
        //Transfer DogeMoon NFT from contract to sender
        dogeMoonContract.safeTransferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokens = _removeFromTokens(tokenId);
        
        return true;
    }
    
    /**
     * @dev Set DOGEMOON token address 
     */
    function getDogeMoonTokenAddress() external view override returns(address){
        return _dogeMoonTokenAddress;
    }
    
    /**
     * @dev Set DOGEMOON token address 
     */
    function getDogeMoonContractAddress() external view override returns(address){
        return _dogeMoonNftAddress;
    }
    
    /**
     * @dev Get all active tokens that can be purchased 
     */ 
    function getTokens() external view returns(uint256[] memory){
        return _tokens;
    }
    
    /**
     * @dev Get token info about price and owner
     */ 
    function getTokenInfo(uint tokenId) external view returns(address, uint){
        return (_tokenOwners[tokenId], _tokenPrices[tokenId]);
    }
    
    /**
     * @dev Get purchase fee percent, this fee is for seller
     */ 
    function getFeePercent() external view override returns(uint){
        return _feePercent;
    }
    
    function getMarketHistories(uint256 tokenId) external view returns(MarketHistory[] memory){
        return _marketHistories[tokenId];
    }
    
    /**
     * @dev Get token price
     */ 
    function getTokenPrice(uint256 tokenId) external view returns(uint){
        return _tokenPrices[tokenId];
    }
    
    /**
     * @dev Get token's owner
     */ 
    function getTokenOwner(uint256 tokenId) external view returns(address){
        return _tokenOwners[tokenId];
    }
    
    /**
     * @dev User purchases a DOGEMOON category
     */ 
    function purchase(uint tokenId) external override returns(uint){
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0),"Token has not been added");
        
        uint256 tokenPrice = _tokenPrices[tokenId];
        
        if(tokenPrice > 0){
            IBEP20 dogeMoonTokenContract = IBEP20(_dogeMoonTokenAddress);    
            require(dogeMoonTokenContract.transferFrom(_msgSender(), address(this), tokenPrice));
            uint256 feeAmount = 0;
            if(_feePercent > 0){
                feeAmount = tokenPrice.mul(_feePercent).div(1000);
                require(dogeMoonTokenContract.transfer(_owner, feeAmount));
            }
            require(dogeMoonTokenContract.transfer(tokenOwner, tokenPrice.sub(feeAmount)));
        }
        
        //Transfer DogeMoon NFT from contract to sender
        IERC721(_dogeMoonNftAddress).transferFrom(address(this),_msgSender(), tokenId);
        
        _marketHistories[tokenId].push(MarketHistory({
            buyer: _msgSender(),
            seller: _tokenOwners[tokenId],
            price: tokenPrice,
            time: block.timestamp
        }));
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        _tokens = _removeFromTokens(tokenId);
        
        emit Purchased(_msgSender(), tokenId, tokenPrice);
        
        return tokenPrice;
    }
    
    /**
     * @dev Set DOGEMOON contract address 
     */
    function setDogeMoonContractAddress(address newAddress) external override onlyOwner{
        require(newAddress != address(0), "Zero address");
        _dogeMoonNftAddress = newAddress;
    }
    
    /**
     * @dev Set DOGEMOON token address 
     */
    function setDogeMoonTokenAddress(address newAddress) external override onlyOwner{
        require(newAddress != address(0), "Zero address");
        _dogeMoonTokenAddress = newAddress;
    }
    
    /**
     * @dev Get DOGEMOON token address 
     */
    function setFeePercent(uint feePercent) external override onlyOwner{
        _feePercent = feePercent;
    }
    
    function owner() external view returns(address){
        return _owner;
    }
    
    function setContractOwner(address newOwner) external onlyOwner{
        require(newOwner != address(0), "Zero address");
        require(newOwner != _owner, "Same owner");
        _owner = newOwner;
        emit ContractOwnerChanged(newOwner);
    }
    
    /**
     * @dev Remove token item by value from _tokens and returns new list _tokens
     */ 
    function _removeFromTokens(uint tokenId) internal view returns(uint256[] memory){
        uint256 tokenCount = _tokens.length;
        uint256[] memory result = new uint256[](tokenCount-1);
        uint256 resultIndex = 0;
        for(uint tokenIndex = 0; tokenIndex < tokenCount; tokenIndex++){
            uint tokenItemId = _tokens[tokenIndex];
            if(tokenItemId != tokenId){
                result[resultIndex] = tokenItemId;
                resultIndex++;
            }
        }
        
        return result;
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
    
    event ContractOwnerChanged(address owner);
    event NewSellOrderCreated(address seller, uint256 tokenId, uint256 price);
    event Purchased(address buyer, uint256 tokenId, uint256 price);
}