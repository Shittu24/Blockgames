// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // External contract that will old stacked funds
    ExampleExternalContract public exampleExternalContract;

    // Balances of the user's stacked funds
    mapping(address => uint256) public balances;

    // Staking threshold
    uint256 public constant threshold = 1 ether;

    // Staking deadline
    uint256 public deadline = block.timestamp + 72 hours;

    // Contract's Events
    event Stake(address indexed sender, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Contract's modifiers
    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }

    function execute() public stakeNotCompleted {
        uint256 contractBalance = address(this).balance;

        // check the contract has enough ETH to reach the treshold
        //  require(contractBalance >= threshold, "Threshold not reached");

        if (contractBalance >= threshold) {
            (bool sent, ) = address(exampleExternalContract).call{
                value: contractBalance
            }(abi.encodeWithSignature("complete()"));
            require(sent, "exampleExternalContract.complete failed");
        } else {
            withdraw();
        }
    }

    function stake() public payable {
        // update the user's balance
        balances[msg.sender] += msg.value;

        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, msg.value);
    }

    function withdraw() public stakeNotCompleted {
        uint256 userBalance = balances[msg.sender];

        // check if the user has balance to withdraw
        require(userBalance >= 0, "You don't have balance to withdraw");

        // reset the balance of the user
        balances[msg.sender] = 0;

        // Transfer balance back to the user
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user balance back to the user");
    }

    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        return stake();
    }
}
