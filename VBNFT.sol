// SPDX-License-Identifier: MITT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VBNFT is ERC721, ERC721Enumerable{
    using Counters for Counters.Counter;
    uint256 public MAX_SUPPLY;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("VoterBlock", "VB") {
        MAX_SUPPLY=100;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://images-platform.99static.com/ZGWMPGt5Yll4-wKR0grdDrFuLv8=/500x500/top/smart/99designs-contests-attachments/49/49133/attachment_49133556";
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

