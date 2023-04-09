// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../contracts/ColonyChef.sol";
import "../contracts/TestClnyToken.sol";
import "../contracts/TestLPToken.sol";

contract StakingTest is Test {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 toPay;
    }

    ColonyChef chef;
    TestClnyToken clny;
    TestLPToken lp;
    address pool = address(4343);
    address user1 = address(534533455);
    address user2 = address(243423423);

    function setUp() public {
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        clny = new TestClnyToken();
        lp = new TestLPToken();
        chef = new ColonyChef(clny, lp, pool, uint(2100 ether) / uint(1 days), block.timestamp + 1 days);
    }

    function testFlow() public {
        clny.approve(address(chef), type(uint256).max);
        lp.transfer(user1, 100 ether);
        lp.transfer(user2, 100 ether);
        vm.prank(user1);
        lp.approve(address(chef), type(uint256).max);
        vm.prank(user2);
        lp.approve(address(chef), type(uint256).max);

        vm.prank(user1);
        chef.deposit(10 ether);
        vm.warp(1 days);
        vm.prank(user1);
        chef.withdraw(10 ether);

        // User1 stakes after 24h
        vm.warp(1 days);
        vm.prank(user1);
        chef.deposit(10 ether);
        // User2 stakes
        vm.startPrank(user2);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        chef.deposit(1 ether);
        // User1 unstakes after 24h
        vm.warp(1 days);
        (uint256 amount, uint256 rewardDebt, uint256 toPay) = chef.userInfo(user1);
        changePrank(user1);
        chef.withdraw(amount);
        // User2 unstakes
        (uint256 amount2, uint256 rewardDebt2, uint256 toPay2) = chef.userInfo(user2);
        changePrank(user2);
        chef.withdraw(amount2);
    }
}
