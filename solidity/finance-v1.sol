pragma solidity 0.5.11;

contract Deposits {

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
        emit Withdrawn(msg.sender, balance);
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}