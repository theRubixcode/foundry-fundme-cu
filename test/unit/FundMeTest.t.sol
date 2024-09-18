// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  address USER = makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  uint256 constant GAS_PRICE = 1;

  function setUp() external {
    // fundMe = new FundMe();
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();

    vm.deal(USER, STARTING_BALANCE);
  }

  function testMinimumDollarIsFive() public view {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() public view {
    console.log(fundMe.getOwner());
    console.log(msg.sender);
    assertEq(fundMe.getOwner(), msg.sender);
  }

  function testPriceFeedVersion() public view {
    uint256 version = fundMe.getVersion();
    console.log(version);
    assertEq(version, 4);
  }

  function testNotEnoughFund() public {
    vm.expectRevert();
    // assert(This tx fails/reverts)
    fundMe.fund(); //sending 0 ETH
  }

  function testFundStructure() public {
    vm.prank(USER); // The next 'tx' will be sent by user

    fundMe.fund{value: SEND_VALUE}();
    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
  }

  function testAddFundersArray() public {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();

    address funder = fundMe.getFunder(0);
    assertEq(funder, USER);
  }
  
  modifier funded {
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    _;
  }

  function testOnlyOwnerCanWithdraw() public funded {
    vm.expectRevert();
    vm.prank(USER);
    fundMe.withdraw();
  }

  function testWithdrawWithASingleFunder() public funded {
    // Arange
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    uint256 gasStart = gasleft(); // let say, 1000
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw(); // let say, used 200

    uint256 gasEnd = gasleft(); // then it will 800
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
    console.log(gasUsed);

    // Assert
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(
      startingFundMeBalance + startingOwnerBalance,
      endingOwnerBalance
    );
  }

  function testWithdrawFromMultipleFunders() public funded {
    // Arrange
    uint160 numberOfFunders = 10;
    uint160 startingFunderIndex = 2;
    for(uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
      // vm.prank new address
      // vm.deal new address
      // hoax = mix of both above
      hoax(address(i), STARTING_BALANCE);
      fundMe.fund{value: SEND_VALUE}();
    }

    uint256 startingFundMeBalance = address(fundMe).balance;
    uint256 startingOwnerBalance = fundMe.getOwner().balance;

    // Act
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    // Assert
    assert(address(fundMe).balance == 0);
    assert(
      startingFundMeBalance + startingOwnerBalance ==
        fundMe.getOwner().balance
    );
    assert(
      (numberOfFunders + 1) * SEND_VALUE == 
        fundMe.getOwner().balance - startingOwnerBalance
    );
  }
}