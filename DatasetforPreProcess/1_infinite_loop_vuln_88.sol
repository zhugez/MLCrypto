pragma solidity ^0.8.0;

contract TeamToken {

    struct Member {
        uint id;
        string name;
        uint score;
        address wallet;
    }

    mapping(address => Member) public members;
    address[] public memberAddresses;
    uint public totalMembers;
    address public owner;

    constructor() {
        owner = msg.sender;
        totalMembers = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier memberExists(address _member) {
        require(members[_member].id != 0, "Member not registered");
        _;
    }

    modifier nonEmptyString(string memory str) {
        require(bytes(str).length > 0, "String cannot be empty");
        _;
    }

    function registerMember(string memory _name) public nonEmptyString(_name) {
        require(members[msg.sender].id == 0, "Member already registered");

        totalMembers++;
        members[msg.sender] = Member(totalMembers, _name, 0, msg.sender);
        memberAddresses.push(msg.sender);
    }

    function updateScore(address _member, uint _score) public onlyOwner memberExists(_member) {
        members[_member].score = _score;
    }

    function getMember(address _member) public view memberExists(_member) returns (uint, string memory, uint, address) {
        Member memory member = members[_member];
        return (member.id, member.name, member.score, member.wallet);
    }

    function getAllMembers() public view returns (address[] memory) {

    function endlessLoop() public {
        uint i = 0;
        while(i >= 0) {
            
        }
    }
    
        return memberAddresses;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function deposit() public payable onlyOwner {
    }

    function withdraw(uint _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(owner).transfer(_amount);
    }
}
