//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {IToken} from "./IToken.sol";


abstract contract Vault is IToken {
    address public asset;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping ())

    constructor() {
        address _asset,
        string _name,
        string _symbol,
        string _decimals,
        uint _tokenID,
        address _onchainID,
        string constant _version = "4.1.3",

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

    event deposit(address _to,uint256 shares, uint256 assets);

    event withdraw(address _to,uint256 shares,uint256 assets);

    ///////////////////////////////////////////////
    // function
    /////////////////////////////////////////////
    function setAsset(uint tokenID) public returns(address){

    }
    function getAsset()public view returns(address){
        
    }


}