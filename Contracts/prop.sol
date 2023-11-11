// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";

contract ProposalContract {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    address owner;
    address[] private voted_addresses;

    constructor() {
        owner = msg.sender;
        voted_addresses.push(owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier active() {
        require(proposalHistory[_counter.current()].isActive == true, "The proposal is not active");
        _;
    }

    modifier newVoter(address _address) {
       require(!isVoted(_address), "Address has not voted yet");
         _;
    }

    // Our contract code
    struct Proposal {
        string title; // Title of the proposal
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 totalVoteToEnd; // When the total votes in the proposal reaches this limit, proposal ends
        bool currentState; // This shows the current state of the proposal, meaning whether if passes or fails
        bool isActive; // This shows if others can vote to our contract
    }

    mapping(uint256 => Proposal) public proposalHistory; // Recordings of previous proposals

    function create(
        string calldata title,
        string calldata description,
        uint256 totalVoteToEnd
    ) external onlyOwner {
        _counter.increment();
        uint256 proposalId = _counter.current();
        proposalHistory[proposalId] = Proposal(
            title,
            description,
            0,
            0,
            0,
            totalVoteToEnd,
            false,
            true
        );
    }

    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }

    function viewOwner() public view returns (address) {
        return owner;
    }

    function vote(uint8 choice) external active {
        require(choice >= 0 && choice <= 2, "Invalid voting choice");

        // Fix the issue of modifying the state of the current proposal when the proposal is not active
        Proposal storage proposal = proposalHistory[_counter.current()];
        if (proposal.isActive == false) {
            return;
    }

        uint256 totalVote = proposal.approve + proposal.reject + proposal.pass;

        voted_addresses.push(msg.sender);

        if (choice == 1) {
            proposal.approve += 1;
        } else if (choice == 2) {
            proposal.reject += 1;
        } else if (choice == 0) {
            proposal.pass += 1;
        }

        proposal.currentState = calculateCurrentState();

        if (
            proposal.totalVoteToEnd - totalVote == 1 &&
            (choice == 1 || choice == 2 || choice == 0)
        ) {
            proposal.isActive = false;
            voted_addresses = [owner];
        }
    }

    function calculateCurrentState() private view returns (bool) {
        return proposalHistory[_counter.current()].approve > proposalHistory[_counter.current()].reject;
    }

    function isVoted(address _address) public view returns (bool) {
        for (uint i = 0; i < voted_addresses.length; i++) {
            if (voted_addresses[i] == _address) {
                return true;
            }
        }
    return false;
    }

    function terminateProposal() external onlyOwner active {
        proposalHistory[_counter.current()].isActive = false;
    }

    function getCurrentProposal() external view returns(Proposal memory) {
        return proposalHistory[_counter.current()];
    }

    function getProposal(uint256 number) external view returns(Proposal memory) {
    return proposalHistory[number];
}
}