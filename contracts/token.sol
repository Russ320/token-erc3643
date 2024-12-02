//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./tokenVault.sol";
import "./IToken.sol";
contract Token is IToken,tokenVault{

    uint256 public constant GOLD =0;
    uint256 public constant SILVER =1;
    uint256 public constant IRON =2;
    uint256 public constant DIA =3;
    



    struct TokenMetadata{
        string name;
        string symbol;
        uint8 decimals;
        address onchainID;
    }
    mapping (uint256 => TokenMetadata) private tokenMetadata;
    mapping(uint256 =>bool) private tokenPaused;

    /// modifier
    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused(uint256 _tokenID) {
        require(!tokenPaused[_tokenID], "Pausable: paused");
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused(uint256 _tokenID) {
        require(tokenPaused[_tokenID], "Pausable: not paused");
        _;
    }

    
    /// function


    function init(
        address _identityRegistry,
        address _compliance,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _onchainID,
        uint _ID
        )external initializer{
            require(owner() == address(0), "already initialized");

            require(
                _identityRegistry != address(0)
                && _compliance != address(0)
            , "invalid argument - zero address");

            require(
                keccak256(abi.encode(_name)) != keccak256(abi.encode(""))
                && keccak256(abi.encode(_symbol)) != keccak256(abi.encode(""))
            , "invalid argument - empty string");
            
            require(0 <= _decimals && _decimals <= 18, "decimals between 0 and 18");

            __Ownable_init();
            _tokenID = _ID;
            

            // set token tokenMetadata[_tokenID]
            tokenMetadata[_ID] = TokenMetadata({
                name : _name,
                symbol: _symbol,
                decimals:_decimals,
                onchainID: _onchainID,
                _tokenPaused = true;
            })
            
            setIdentityRegistry(_identityRegistry);
            setCompliance(_compliance);
            emit UpdatedTokenInformation(_tokenName, _tokenSymbol, _tokenDecimals, _TOKEN_VERSION, _tokenOnchainID,_tokenID);


        }

        function setName(string calldata _name, uint calldata _tokenID) external override onlyOwner{
            require(keccak256(abi.encode(_name))!= keccak256(abi.encode("")),"invalid argument -empty string");
            require(keccak256(abi.encode(_name))!= keccak256(abi.encode(tokenMetadata[_tokenID].name)),"invalid name - new name same as old name");
            tokenMetadata[_tokenID].name = _name;
            emit UpdatedTokenInformation(tokenMetadata[_tokenID].name,tokenMetadata[_tokenID].symbol,tokenMetadata[_tokenID].decimals,_TOKEN_VERSION,tokenMetadata[_tokenID].onchainID,_tokenID);
        }
        function setSymbol(string calldata _symbol,uint calldata _tokenID) external override onlyOwner{
            require(keccak256(abi.encode(_symbol))!= keccak256(abi.encode("")),"invalid argument -empty string");
            require(keccak256(abi.encode(_symbol))!= keccak256(abi.encode(tokenMetadata[_tokenID].symbol)),"invalid name - new name same as old name");
            tokenMetadata[_tokenID].symbol = _symbol;
            emit UpdatedTokenInformation(tokenMetadata[_tokenID].name,tokenMetadata[_tokenID].symbol,tokenMetadata[_tokenID].decimals,_TOKEN_VERSION,tokenMetadata[_tokenID].onchainID,_tokenID);
        }

        function setOnchainID(address _onchainID,uint calldata _tokenID) external override onlyOwner{
            TokenMetadata memory tokenMetadata[_tokenID] = tokenMetadata[_tokenID];
            tokenMetadata[_tokenID].onchainID = _onchainID;
            emit UpdatedTokenInformation(tokenMetadata[_tokenID].name,tokenMetadata[_tokenID].symbol,tokenMetadata[_tokenID].decimals,_TOKEN_VERSION,tokenMetadata[_tokenID].onchainID,_tokenID);
        }
        function pauseToken(uint256 _tokenID) external onlyOwner whenNotPaused(_tokenID){
            tokenPaused[_tokenID] = true;
            emit TokenPaused(msg.sender,_tokenID);
        }

        function unpauseToken(uint256 _tokenID) external onlyOwner whenPaused(_tokenID){
            tokenPaused[_tokenID] = false;
            emit Unpaused(msg.sender,_tokenID);
        }
        function batchTransfer(address[] calldata _toList,uint _tokenID,uint256[] calldata _amounts)external override{
            
            for (uint256 i = 0; i <_toList.length;i++){
                transfer(_toList[i],_tokenID,_amounts[i])
            }
        }
        function batchBurn(address[] calldata _userAddresses, uint _tokenID, uint256[] calldata _amounts)external override{
            for(uint256 i=0; i< _userAddresses.length;i++){
                burn(_userAddresses[i],_amounts[i],_tokenID);
            }

        }
        function batchMint(address[] calldata _toList, uint _tokenID,uint256[] _amounts) external override{
            for (uint256 i = 0; i <_toList.length;i++){
                mint(_toList[i],_amounts[i],_tokenID);
            }
        }
        function batchForcedTransfer(
            address[] calldata _fromList,
            address[] calldata _toList,
            uint256[] calldata _amounts,
            uint _tokenID
        ) external override{
            for(uint256 i =0; i< _fromList; i++){
                forcedTransfer(_fromList[i],_toList[i],_amounts[i],_tokenID);
            }
        };

        function batchFreezePartialTokens(address[] calldata _userAddresses,uint _tokenID, uint256[] calldata _amounts) external override{
            for(uint256 i=0; i<_userAddresses;i++){
                freezePartialTokens(_userAddresses[i],_amounts[i],_tokenID);
            }
        }
        function batchUnfreezePartialTokens(address[]calldata _userAddresses,uint _tokenID,uint256[] _amounts)external override{
            for(uint256 i=0; i<_userAddresses;i++){
                unfreezePartialTokens(_userAddresses[i],_amounts[i],_tokenID);
            }
        }
        function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external override{
            for(uint256 i=0; i<_userAddresses;i++){
                setAddressFrozen(_userAddresses[i],_freeze[i]);
            }
        }
        
        function transfer(address _to,uint _tokenID,uint256 _amounts) external override whenNotPaused(_tokenID) returns(bool){

        }
        function totalSupply() external view override returns(uint256){
            return _totalSupply;
        }
        function identityRegistry() external view override returns(IIdentityRegistry){
            
            return _identityRegistry;
        }
        function compliance()external view override returns(IIdentityRegistry){
            return _tokenCompliance;
        }
        function paused(uint _tokenID) external view override returns(bool){
            return tokenPaused[_tokenID]
        }
        function isFrozen(address _userAddress) external view override returns(bool){
            return 
        }

        function decimals(uint _tokenID) external view override returns(uint256){
            
            return tokenMetadata[_tokenID].decimals;
        }

        function name(uint _tokenID) external view override returns(string){
            return tokenMetadata[_tokenID].name;
        }

        function onchainID(uint _tokenID) external view override returns(address){
            return tokenMetadata[_tokenID].onchainID;
        }
        function symbol(uint _tokenID)external view override returns(string){
            return tokenMetadata[_tokenID].symbol;
        }

        function version() external pure override returns (string memory) {
            return _TOKEN_VERSION;
        }


}