pragma solidity 0.5.11;

// We are not implementing safeMath, this contract only exists
// as a comparison exersice for people with background
// in solidity and want to try LIGO
contract v3FullPool {

    struct DepositInfo {
      uint256 timestamp;
      uint256 amount;
    }

    mapping(address => DepositInfo) deposits;

    function calculateInterest(uint256 elapsedBlocks) private pure returns (uint256) {
        if(elapsedBlocks > 10) {
            return 0.1 ether;
        } else {
            return 0 ether;
        }
    }

    function deposit() public payable {
        uint256 amount = msg.value;
        address payee = msg.sender;
        uint256 currentBlock = block.number;

        if(deposits[payee].timestamp != 0) {
            DepositInfo storage di = deposits[payee];
            di.amount = di.amount + calculateInterest(currentBlock - di.timestamp) + amount;
            di.timestamp = currentBlock;
        } else {
            DepositInfo memory di = DepositInfo({timestamp: currentBlock, amount: amount});
            deposits[payee] = di;
        }
    }

    function withdraw() public {
        address payable payee = msg.sender;

        DepositInfo memory di = deposits[payee];
        uint256 payment = di.amount + calculateInterest(block.number - di.timestamp);
        
        require(address(this).balance >= payment, "No Ether available to make the withdraw!");
        
        delete deposits[payee];

        payee.transfer(payment);
    }
}