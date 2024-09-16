// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
  FundMe fundMe;

  function setUp() external {
    // fundMe = new FundMe();
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
  }

  function testMinimumDollarIsFive() public view {
    assertEq(fundMe.MINIMUM_USD(), 5e18);
  }

  function testOwnerIsMsgSender() public view {
    console.log(fundMe.i_owner());
    console.log(msg.sender);
    assertEq(fundMe.i_owner(), msg.sender);
  }

  function testPriceFeedVersion() public view {
    uint256 version = fundMe.getVersion();
    console.log(version);
    assertEq(version, 4);
  }
}