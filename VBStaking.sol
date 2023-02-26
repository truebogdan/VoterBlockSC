pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is IERC721Receiver, Ownable {
    struct Stake {
        uint256 tokenId;
        uint256 startDate;
        uint256 endDate;
        bool isWithdrawn;
    }

    mapping (address => Stake[]) public stakes;
    mapping (address => uint256) public totalStaked;

    IERC721 public nft;
    uint256 public lockupPeriod;

    event Staked(address indexed staker, uint256 indexed tokenId);
    event Unstaked(address indexed staker, uint256 indexed tokenId);

    constructor(IERC721 _nft, uint256 _lockupPeriod) {
        nft = _nft;
        lockupPeriod = _lockupPeriod;
    }

    function stake(uint256 tokenId) external {
        require(nft.ownerOf(tokenId) == msg.sender, "You don't own this token");
        // Transfer the token to the staking contract
        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        // Add a new stake to the staker's list of stakes
        stakes[msg.sender].push(Stake({
            tokenId: tokenId,
            startDate: block.timestamp,
            endDate: block.timestamp + lockupPeriod,
            isWithdrawn: false
        }));

        // Update the total number of tokens staked by the staker
        totalStaked[msg.sender]++;

        emit Staked(msg.sender, tokenId);
    }

    function unstake(uint256 stakeIndex) external {
        require(stakes[msg.sender].length > stakeIndex, "Invalid stake index");

        Stake storage stakeToWithdraw = stakes[msg.sender][stakeIndex];

        require(!stakeToWithdraw.isWithdrawn, "Stake has already been withdrawn");
        require(block.timestamp >= stakeToWithdraw.endDate, "Lockup period not over yet");

        uint256 tokenIdToWithdraw = stakeToWithdraw.tokenId;

        // Mark the stake as withdrawn
        stakeToWithdraw.isWithdrawn = true;

        // Transfer the staked token back to the staker
        nft.safeTransferFrom(address(this), msg.sender, tokenIdToWithdraw);

        // Update the total number of tokens staked by the staker
        totalStaked[msg.sender]--;

        emit Unstaked(msg.sender, tokenIdToWithdraw);
    }

    function getStakes(address staker) public view returns (Stake[] memory) {
        return stakes[staker];
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
