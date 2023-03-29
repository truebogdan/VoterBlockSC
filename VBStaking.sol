// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VBNFT.sol";

contract VBStaking is IERC721Receiver, Ownable {
    struct Stake {
        uint256 tokenId;
        uint256 startDate;
        uint256 endDate;
        bool isWithdrawn;
    }

    mapping (address => Stake[]) public stakes;
    mapping (address => uint256) public totalStaked;
    mapping(uint256 => bool) tokenStakedMap;
    mapping(uint256 => address) tokenOwnerMap;
    VBNFT public nft;
    uint256 public lockupPeriod;

    event Staked(address indexed staker, uint256 indexed tokenId);
    event Unstaked(address indexed staker, uint256 indexed tokenId);

    constructor(VBNFT _nft) {
        nft = _nft;
        lockupPeriod = 10;
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
        tokenStakedMap[tokenId] = true;
        tokenOwnerMap[tokenId] = msg.sender;
        emit Staked(msg.sender, tokenId);
    }

    function unstake(uint256 tokenId) external {
        uint256 stakeIndex = getStakeByTokenId(tokenId , msg.sender);
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
        tokenStakedMap[tokenId] = false;
        tokenOwnerMap[tokenId]= address(0);
        emit Unstaked(msg.sender, tokenIdToWithdraw);
    }
    function getStakeByTokenId(uint256 tokenId, address sender) private view returns(uint stakeId)
    {
        Stake[] memory senderStakes = stakes[sender];
        for(uint i=0 ; i< senderStakes.length; i++){
            if(senderStakes[i].tokenId == tokenId && senderStakes[i].isWithdrawn == false)
            {
                return i;
            }
        }
        return 0;
    }

    function getVotingPower() public view returns(address[] memory , uint256[] memory)
    {
        address[] memory stakers = getAllStakers();
        uint256[] memory power = new uint256[](stakers.length);
        for(uint256 i=0; i< stakers.length;i++)
        {
             power[i] = totalStaked[stakers[i]]; 
        }

        return (stakers, power);
    }

    function getAllStakers() public view returns(address[] memory)
    {
        uint256[] memory stakedTokenIds = getAllStakedTokens();
        address[] memory stakers = new address[](stakedTokenIds.length);
        for(uint256 i=0; i<stakers.length;i++)
        {
            stakers[i] = tokenOwnerMap[stakedTokenIds[i]];
        }

        uint256 index =0 ;
        address[] memory uniqueStakers = new address[](stakers.length);
        for(uint256 i=0; i<stakers.length;i++)
        {
            if(CheckIfAddressIsUniqueInArray(i+1, stakers[i], stakers))
            {
                uniqueStakers[index] = stakers[i];
                index++;
            }
        }


        address[] memory uniqueStakersWithout0Address = new address[](index);
        for(uint256 i=0; i<index;i++)
        {
            uniqueStakersWithout0Address[i] = uniqueStakers[i];
        }

        return uniqueStakersWithout0Address;
    }

    function CheckIfAddressIsUniqueInArray(uint256 index, address staker, address[]memory stakers) private pure returns(bool) {
        for(uint256 i=index;i<stakers.length;i++){
            if(stakers[i]==staker)
            {
                return false;
            }
        }
        return true;
    }

    function getAllStakedTokens() public view returns(uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](nft.totalSupply());
        uint256 index = 0;
        for(uint256 i = 0; i< nft.totalSupply() ; i++)
        {
            if(tokenStakedMap[i]==true)
            {
                tokenIds[index] = i;
                index++;
            }
        }

        uint256[] memory tokenIdsCopy = new uint256[](index);
        for(uint256 i=0;i<index;i++)
        {
            tokenIdsCopy[i]=tokenIds[i];
        }

        return tokenIdsCopy;
    }
    function getStakes(address staker) public view returns (Stake[] memory) {
        return stakes[staker];
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
