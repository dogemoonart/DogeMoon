// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDogeMoonMarket{
    /**
     * @dev User that created sell order can cancel that order
     */ 
    function cancelSellOrder(uint256 tokenId) external returns(bool);
    
    /**
     * @dev Create a sell order to sell DOGEMOON category
     */
    function createSellOrder(uint tokenId, uint price) external returns(bool);
    
    /**
     * @dev Set DOGEMOON contract address 
     */
    function getDogeMoonContractAddress() external view returns(address);
    
     /**
     * @dev Set DOGEMOON token address 
     */
    function getDogeMoonTokenAddress() external returns(address);
    
    /**
     * @dev Get purchase fee percent, this fee is for seller
     */ 
    function getFeePercent() external returns(uint);
    
    /**
     * @dev User purchases a DOGEMOON category
     */ 
    function purchase(uint tokenId) external returns(uint);
    
     /**
     * @dev Get DOGEMOON token address 
     */
    function setDogeMoonTokenAddress(address newAddress) external;
    
    /**
     * @dev Get DOGEMOON token address 
     */
    function setDogeMoonContractAddress(address newAddress) external;
    
    /**
     * @dev Set fee percent
     */ 
    function setFeePercent(uint feePercent) external;
}