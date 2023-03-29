// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./VoterBlock.sol";

contract VBSGov { 

VoterBlock private _voterblock;
constructor(VoterBlock voterblockContract){
    _voterblock = voterblockContract;
}
    event ProposalCompleted(uint256 _type, uint256 effect);
    struct GovPoll {
        string title;
        address author;
        uint256 effect;
        uint256 deadline;
        uint256 yes;
        uint256 _type;
        uint256 no;
        address[] voters;
        uint256 [] power;
        bool[] votersCheckList;
        bool completed;
    }
    GovPoll[] public polls;

    function createPoll(string memory title, uint256 effect ,uint256 _type) public {
        uint256 pollIndex = polls.length;
        polls.push();
        GovPoll storage poll = polls[pollIndex];
        poll.title = title; 
        poll.author = msg.sender;
        poll.effect = effect;
        poll._type = _type;
        poll.deadline = block.timestamp + 86400;
        (address[] memory stakers, uint256[] memory power ) = _voterblock.getVotingPower();
        poll.voters = stakers;
        poll.power = power;
        poll.votersCheckList = new bool[](stakers.length);
    }

    function getPowerForAddress(address staker) public view returns (uint256)
    {
        (address[] memory stakers, uint256[] memory power ) = _voterblock.getVotingPower();
        for(uint256 i=0;i<stakers.length;i++){
            if(stakers[i] == staker)
            {
                return power[i];
            }
        }

        return 0;
    }

    function getPollData(uint256 id) public view returns(address[] memory,uint256[] memory,bool[] memory)
    {
        GovPoll memory poll = polls[id];
        return(poll.voters, poll.power, poll.votersCheckList);
    }

    function getPollsNumber() public view returns (uint256)
    {
        return polls.length;
    }

    function voteYes(uint256 pollId) public {
        GovPoll storage poll  = polls[pollId];
        bool canVote = CheckIfAddressCanVote(msg.sender, poll);
        require(canVote == true, "Sender can't vote for this poll");
        require(poll.completed == false);
        for(uint256 i=0;i<poll.voters.length;i++)
        {
            if(poll.voters[i] == msg.sender)
            {
                poll.yes+= poll.power[i];
                poll.votersCheckList[i]=true;
            }
        }
    }

    function voteNo(uint256 pollId) public{
        GovPoll storage poll  = polls[pollId];
        bool canVote = CheckIfAddressCanVote(msg.sender, poll);
        require(canVote == true, "Sender can't vote for this poll");
        require(poll.completed == false, "Poll is completed");
        for(uint256 i=0;i<poll.voters.length;i++)
        {
            if(poll.voters[i] == msg.sender)
            {
                poll.no+= poll.power[i];
                poll.votersCheckList[i]=true;
            }
        }
    }

    function completePoll(uint256 pollId) public {
        GovPoll storage poll  = polls[pollId];
        bool canComplete = CheckIfAddressCanComplete(msg.sender, poll);
        require(canComplete == true, "Sender can't complete this poll");
        require(poll.completed == false , "Poll is already completed");
        uint256 turnout = CalculateTurnout(poll.votersCheckList);
        require(turnout >= 80, "Turnout should be greater than 80%");
        require(poll.yes > poll.no);
        poll.completed = true;
        if(poll._type == 1){
        _voterblock.setCreationCost(poll.effect);
        }
        emit ProposalCompleted(poll._type, poll.effect);
    }
    
    function CalculateTurnout(bool[] memory checkList) public pure returns(uint256)
    {
        uint256 total = checkList.length;
        uint256 sum =0;
        for(uint256 i=0;i<total;i++)
        {
            if(checkList[i]==true)
            {
                sum++;
            }
        }
        return sum/total*100;
    }

    function CheckIfAddressCanComplete(address sender, GovPoll memory poll) private pure returns(bool){
        
        for(uint256 i=0 ; i< poll.voters.length; i++)
        {
            if(sender == poll.voters[i])
            {   
                return true;
            }
        }

        return false;
    }


    function CheckIfAddressCanVote(address sender, GovPoll memory poll) private pure returns(bool)
    {

        for(uint256 i=0 ; i< poll.voters.length; i++)
        {
            if(sender == poll.voters[i])
            {   
                if(poll.votersCheckList[i] == false)
                {
                    return true;
                }
                    return false;
            }
        }

        return false;
    }


}
