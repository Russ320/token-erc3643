//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {IToken} from "./IToken.sol";


abstract contract NFTTokens is IToken {
    address public asset;

    constructor() {
        string memory _name,
        string memory _symbol,
        address _asset
    }
    ERC20("Vault"){
        asset = _asset;
    }
    ////////////////////////////////////////////////
    // EVENT 
    ///////////////////////////////////////

    /**
     * this event is emiited when the token is asseted to the vault
     * @param tokenID is the id of a token 
     * @param _operator is the address of operator asseted token
     */
    event addTokenAsset(uint tokenID,address _operator);

    event converted(uint tokenID, uint256 _amount);

    event deposit(address _to,uint256 _amount);

    event withdraw(address _to,uint256 _amount);
    ///////////////////////////////////////////////
    // function
    /////////////////////////////////////////////
    function setAsset() public returns()
    function getAsset()public view returns(address){
        
    }
}