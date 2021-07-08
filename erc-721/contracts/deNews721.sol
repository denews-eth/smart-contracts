pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title deNews721
 * deNews721 - Smart contract for deNews NFTs
 */
contract deNews721 is ERC721Full, Ownable {

    mapping (string => address) private _authorsMappings;
    mapping (uint256 => string) private _tokenIdsMapping;
    mapping (string => uint256) private _tokenIdsToHashMapping;
    address openseaProxyAddress;
    address umiProxyAddress;
    uint256 private _currentTokenId = 0;
    string public contract_ipfs_json;
    bool public proxyMintingEnabled = true;

    constructor(
        address _openseaProxyAddress,
        string memory _name,
        string memory _ticker,
        string memory _contract_ipfs,
        address _umiProxyAddress
    ) public ERC721Full(_name, _ticker) {
        openseaProxyAddress = _openseaProxyAddress;
        umiProxyAddress = _umiProxyAddress;
        contract_ipfs_json = _contract_ipfs;
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    function enableProxyMinting() public onlyOwner {
        proxyMintingEnabled = true;
    }

    function disableProxyMinting() public onlyOwner {
        proxyMintingEnabled = false;
    }

    function contractURI() public view returns (string memory) {
        return contract_ipfs_json;
    }

    function nftExists(string memory tokenHash) internal view returns (bool) {
        address owner = _authorsMappings[tokenHash];
        return owner != address(0);
    }

    function returnTokenIdByHash(string memory tokenHash) public view returns (uint256) {
        return _tokenIdsToHashMapping[tokenHash];
    }

    function returnTokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenIdsMapping[tokenId];
    }

    function returnCreatorByNftHash(string memory hash) public view returns (address) {
        return _authorsMappings[hash];
    }

    function canMint(string memory tokenURI) internal view returns (bool){
        require(!nftExists(tokenURI), "deNews721: Trying to mint existent nft");
        return true;
    }

    /*
        This method will first mint the token to the address.
    */
    function mintNFT(string memory tokenURI) public returns (uint256) {
        require(canMint(tokenURI), "deNews721: Can't mint token");
        uint256 tokenId = mintTo(msg.sender, tokenURI);
        _authorsMappings[tokenURI] = msg.sender;
        _tokenIdsMapping[tokenId] = tokenURI;
        _tokenIdsToHashMapping[tokenURI] = tokenId;
        return tokenId;
    }

    /*
        This method will mint the token to provided user, can be called just by the proxy address.
    */
    function proxyMintNFT(address to, string memory tokenURI) public returns (uint256) {
        require(proxyMintingEnabled, "deNews721: Proxy minting is disabled");
        require(canMint(tokenURI), "deNews721: Can't mint token");
        require(msg.sender == umiProxyAddress, "deNews721: Only Proxy Address can Proxy Mint");
        uint256 tokenId = mintTo(to, tokenURI);
        _authorsMappings[tokenURI] = to;
        _tokenIdsMapping[tokenId] = tokenURI;
        _tokenIdsToHashMapping[tokenURI] = tokenId;
        return tokenId;
    }

    /*
        Private method that mints the token
    */
    function mintTo(address _to, string memory _tokenURI) private returns (uint256){
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        _incrementTokenId();
        return newTokenId;
    }

    function burnToken(uint256 _tokenId) public returns (bool){
        _burn(msg.sender, _tokenId);
        return true;
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    /*
        This method is used by OpenSea to automate the sell.
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view returns (bool isOperator) {
        if (_operator == address(openseaProxyAddress) || _operator == address(umiProxyAddress)) {
            return true;
        }
        
        return super.isApprovedForAll(_owner, _operator);
    }
}
