// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VoterBlock is ERC721, ERC721Enumerable{
    using Counters for Counters.Counter;
    uint256 public MAX_SUPPLY;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("VoterBlock", "VB") {
        MAX_SUPPLY=100;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://i.pinimg.com/originals/2d/a0/3f/2da03f73141ff61403cccdd3593223ec.jpg";
    }

    function safeMint() public {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + 1 < MAX_SUPPLY);
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }
        // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }
}

