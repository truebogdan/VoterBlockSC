// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "./VBStaking.sol";
contract VoterBlock {
    struct Option {
        string name;
        uint256 votes;
    }

    constructor(VBStaking stakingContract){
        _staking = stakingContract;
    }

    VBStaking private _staking;
    struct Poll {
        string name;
        uint256 index;
        uint256[] optionIds;
        uint256 deadline;
        uint256 votersIndex;
        mapping(address => uint) votersMap;
        address[] votersList;
    }
    Poll[] private  polls;
    Option[] private options;
    uint256 public pollCreationCost = 0.01 ether;
    mapping(address=> uint256) public rewardsMap;


    event PollCreated(uint256 pollIndex);
    event OptionVoted(uint256 votesCount);

    function createPoll (
        string memory name,
        string[] memory optionNames,
        uint256 deadline,
        address[] memory voters
    ) public payable {
        require(msg.value == pollCreationCost);
        uint256 pollIndex = polls.length;
        polls.push();
        Poll storage poll = polls[pollIndex];
        poll.index = pollIndex; 
        poll.name = name;
        poll.deadline = deadline;

        // options
        poll.optionIds = new uint256[](optionNames.length);
        for (uint256 i = 0; i < optionNames.length; i++) {
            //add option index to poll
            poll.optionIds[i] = options.length;
            options.push(Option(optionNames[i], 0));
        }

        // voters
        poll.votersList = new address[](voters.length);
        for(uint256 i=0; i<voters.length; i++)
        {
            poll.votersMap[voters[i]] = 1;
            poll.votersList[0] = voters[i];
        }
        splitRewardToStakers(msg.value);
        emit PollCreated(poll.index);

    }
    function canVote(uint256 index, address sender) public view returns(bool canSenderVote)
    {
        Poll storage poll = polls[index];
        canSenderVote = poll.votersMap[sender] == 1;
    }



    function getPoll(uint256 index)
        public
        view
        returns (
            string memory pollName,
            string[] memory optionsNames,
            uint256[] memory optionsVotes,
            uint256 deadline,
            address[] memory votersList
        )
    {
        Poll storage poll = polls[index];
        pollName = poll.name;
        deadline = poll.deadline;
        optionsNames = new string[](poll.optionIds.length);
        optionsVotes = new uint256[](poll.optionIds.length);
        for (uint256 i = 0; i < poll.optionIds.length; i++) {
            Option storage option = options[poll.optionIds[i]];
            optionsNames[i] = option.name;
            optionsVotes[i] = option.votes;
        }
        votersList = poll.votersList;
    }

    function voteForOption(uint256 index, string memory optionName) public {
        Poll storage poll = polls[index];
        require(poll.deadline/1000 >= block.timestamp);
        require(poll.votersMap[msg.sender] == 1);
        poll.votersMap[msg.sender] = 2;
        poll.votersList.push(msg.sender);
        for (uint256 i = 0; i < poll.optionIds.length; i++) {
            Option storage option = options[poll.optionIds[i]];
            if (compareStrings(option.name, optionName)) {
                option.votes++;
                emit OptionVoted(option.votes);
            }
        }
    }

    function compareStrings(string memory _s1, string memory _s2)
        private
        pure
        returns (bool areEual)
    {
        return
            keccak256(abi.encodePacked(_s1)) ==
            keccak256(abi.encodePacked(_s2));
    }

    function splitRewardToStakers(uint256 reward) private {


       (address[] memory stakers, uint256[] memory power) =  _staking.getVotingPower();

       uint256 powerSum = 0;

       for(uint256 i=0;i<stakers.length;i++){
           powerSum = powerSum + power[i];
       }

       uint256 rewardPart = reward/powerSum;
       for(uint256 i=0;i<stakers.length;i++){
           rewardsMap[stakers[i]] += rewardPart*power[i]; 
       }
    }

    function claimReward() public {
        uint256 reward = rewardsMap[msg.sender];
        require(reward>0);
        payable(msg.sender).transfer(reward);
        rewardsMap[msg.sender] = 0;
    }

    function getVotingPower() public view returns(address[] memory, uint256[] memory) {
        return _staking.getVotingPower();
    }

    function setCreationCost(uint256 newCost) public {
        pollCreationCost = newCost;
    }
}
