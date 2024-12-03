//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
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
        uint64 startTime;
        uint64 endTime;
    }
    mapping (uint256 => TokenMetadata) private tokenMetadata;
    mapping(uint256 =>bool) private tokenPaused;
    mapping(address => bool) private accountFrozen
    mapping(uint256 => mapping(address => uint256)) private _balances; // tokenID => userAddress => balance
    mapping(address =>uint256) private _totalSupply;

    struct UserData{
        uint256 frozenTokens;
        uint256 allowance;
        uint256 asset;
    }

    mapping(uint => mapping(address => UserData)) private userData;

    /// modifier
    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused(uint256 _tokenID) {
        require(!tokenPaused[_tokenID], "Pausable: paused");
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenPaused(uint _tokenID) {
        require(tokenPaused[_tokenID], "Pausable: not paused");
        _;
    }
    modifier validToken(uint _tokenID){
        require(_exists(_tokenID), "ERC5007: invalid tokenId");
        _;
    }
    uint public tokenIDs[] = [GOLD,SILVER,IRON,DIA];
    
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
        function startTime(uint _tokenID) external view validToken(_tokenID) return(uint256){
            return tokenMetadata[tokenID].startTime;
        }

        // @dev return the end time of the NFT as a UNIX timestamp
        function endTime(uint _tokenID) external view validToken(_tokenID) return(uint256){
            return tokenMetadata[tokenID].endTime;
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
        function pause(uint _tokenID) external onlyOwner validToken whenNotPaused(_tokenID){
            tokenPaused[_tokenID] = true;
            emit Paused(msg.sender,_tokenID);
        }

        function unpause(uint _tokenID) external onlyOwner validToken whenPaused(_tokenID){
            tokenPaused[_tokenID] = false;
            emit Unpaused(msg.sender,_tokenID);
        }

        function setAddressFrozen(address _userAddress, bool _freeze,uint64 _time) external override{
            accountFrozen[_userAddress] = _freeze;
            emit AddressFrozen(_userAddress,_freeze,msg.sender,_time);
        }
        function freezePartialTokens(address _userAddress,uint256 _amount,uint _tokenID) external override validToken(_tokenID){
            uint balance = balanceOf(_userAddress,_tokenID);
            require(balance >= userData[_tokenID][_userAddress].frozenTokens + _amount,"amount exceed the available wallet");
            userData[_tokenID][_userAddress].frozenTokens += _amount;
            emit TokensFrozen(_userAddress,_amount,_tokenID);
        }

        function unfreezePartialTokens(address _userAddress,uint256 _amount, uint _tokenID) external override validToken(_tokenID){
            require(frozenTokensOf(_userAddress,_tokenID) >= _amount,"amount should be less than or equal to frozen tokens");
            userData[_tokenID][_userAddress].frozenTokens -= _amount;
            emit TokensUnfrozen(_userAddress,_amount,_tokenID);
        }

        // function setIdentityRegistry(address _identityRegistry) external{}
        // function setCompliance(address _compliance)external{}
        function forcedTransfer(address _from,address _to, uint256 _amount,uint _tokenID) external override onlyAgent returns(bool){
            require(balanceOf(_from,_tokenID) >= _amount,"sender balance too low")
            uint256 freeBalance = balanceOf(_from,_tokenID) - userData[_tokenID][_from].frozenTokens;
            if(_amount > freeBalance){
                uint256 tokenToUnFreeze = _amount - freeBalance;
                userData[_tokenID][_from].frozenTokens -=  tokenToUnFreeze;
                emit TokensUnfrozen(_from,tokenToUnFreeze,_tokenID);
            }
            if(_tokenIdentityRegistry.isVerified(_to)){
                _transfer(_from,_to,_amount,_tokenID);

            }
        }
        // function recoveryAddress( address _lostWallet,address _newWallet,address _investorOnchainID) external override onlyAgent returns(bool){
        //     require(totalBalanceOf(_lostWallet)!= 0,"no tokens to recover");
        //     IIdentity _onchainID = IIdentity(_investorOnchainID);

        // }
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
        }

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
            require(!_frozen[_to] && !_frozen[msg.sender], "wallet is frozen");
            require(_amount <= balanceOf(msg.sender) - (_frozenTokens[msg.sender]), "Insufficient Balance");
            if (_tokenIdentityRegistry.isVerified(_to) && _tokenCompliance.canTransfer(msg.sender, _to, _amount)) {
                _transfer(msg.sender, _to, _amount,_tokenID);
                _tokenCompliance.transferred(msg.sender, _to, _amount,_tokenID);
                return true;
            }
            revert("Transfer not possible");
        
        
        }
        function totalSupply(address _user) external view override returns(uint256){
            return _totalSupply[_user];
        }
        function identityRegistry() external view override returns(IIdentityRegistry){
            
            return _identityRegistry;
        }
        function compliance()external view override returns(IIdentityRegistry){
            return _tokenCompliance;
        }
        function paused(uint _tokenID) external view override returns(bool){
            return tokenPaused[_tokenID];
        }
        function isFrozen(address _userAddress) external view override returns(bool){
            return accountFrozen[_userAddress];
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
        function balanceOf(address _user,uint _tokenID) public view returns(uint256){
            return _balances[_tokenID][_user];
        }
        function totalBalanceOf(address _user) public view returns(uint256){
            uint256 totalBalance;
            for(uint256 i=0; i< tokenIDs.length; i++){
                uint _tokenID = tokenIDs[i];
                totalBalance += balanceOf[_tokenID][_user];
            }
            return totalBalance;
        }
        function frozenTokensOf(address _user, uint _tokenID) public view returns(uint256){
            return userData[_tokenID][_user].frozenTokens;
        }
        function getFrozenTokens(address _userAddress) public view returns(uint256){
            uint256 totalFrozen;
            for(uint256 i=0; i< tokenIDs.length; i++){
                uint _tokenID = tokenIDs[i];
                totalFrozen += userData[_tokenID][_userAddress].frozenTokens;
            }
            return totalFrozen;
        }
        function _transfer(address _from,address _to,address _amount,uint _tokenID) internal virtual{
            require(_from != address(0),"error");
            require(_to != address(0),"error");
            
            balanceOf[_tokenID][_from] -= _amount;
            balanceOf[_tokenID][_from] += _amount;
            emit Transfer(_from,_to,_amount,_tokenID);    
        }
        function _burn(address _userAddress, uint256 _amount, uint _tokenID) internal virtual{
            require(_userAddress != address(0),"burn from zero address");

            _beforTokenTransfer(msg.sender,_userAddress,address(0),_tokenID,_amount,"");
            balanceOf[_tokenID][_userAddress] -= _amount;
            _totalSupply[_userAddress] -= _amount;
            emit Transfer(_userAddress,address(0),_amount);
        }
        function _mint(address _userAddress,uint256 _amount,uint _tokenID) internal virtual{
            require(_userAddress != address(0),"mint to zero address");

            _beforTokenTransfer(msg.sender,address(0),_userAddress,_tokenID,_amount,"");
            _totalSupply[_userAddress] += _amount;
            balanceOf[_tokenID][_userAddress] += _amount;
            emit Transfer(address(0),_userAddress,_amount);
        }
        

}