// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../src/multisender.sol";
import "./lib/MockUser.sol";
import "./lib/MockToken.sol";
import "./lib/CheatCodes.sol";

contract MultiSenderTest is Test {

    using SafeMath for uint256;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    MultiSender public multiSender;

    MockUser[6] public users;
    MockToken public rewardToken;

    uint256 rewardTokenDecimals = 1e18;

    
    function setUp() public {
        multiSender = new MultiSender();
        for(uint8 i = 0; i < 6; ++i){
            users[i] = new MockUser();
        }
        rewardToken = new MockToken();
        rewardToken.mint(address(users[1]), 10000000 * rewardTokenDecimals);
    }


    // deployer adds account 0 as the owner
    function testAddOwner () public {
        multiSender.addOwner(address(users[0]));
    }

    // prank users[0] as the lord & tries to add address[1] as the owner
    function testFailAddOwner () public {
        cheats.startPrank(address(users[0]));
        multiSender.addOwner(address(users[1]));
        cheats.stopPrank();
    }
    // test if owner can add admin, users[0] can add users[1] as the admin
    function testOwnerAddAdmin () public {
        multiSender.addOwner(address(users[0]));
        cheats.startPrank(address(users[0]));
        multiSender.addAdmin(address(users[1]), address(rewardToken));
        cheats.stopPrank();
        cheats.startPrank(address(users[1]));
        rewardToken.transfer(address(multiSender), 200000 * rewardTokenDecimals );
        cheats.stopPrank();
        uint256 depositAmount = rewardToken.balanceOf(address(multiSender));
        console.logString("deposit amount is ");
        console.logUint(depositAmount);
    }

    function testMultiSendToken () public {
        multiSender.addOwner(address(users[0]));
        cheats.startPrank(address(users[0]));
        multiSender.addAdmin(address(users[1]), address(rewardToken));
        cheats.stopPrank();
        cheats.startPrank(address(users[1]));
        rewardToken.transfer(address(multiSender), 200000 * rewardTokenDecimals );
        cheats.stopPrank();
        address[] memory recipients = new address[](3);
        uint[] memory rewards = new uint[](3);
        for(uint256 i = 0; i < 3; ++i){
            recipients[i] = address(users[i+2]);
            rewards[i] = (i+2) * 100 * rewardTokenDecimals;
        }
        cheats.startPrank(address(users[1]));
        multiSender.multiSendToken(address(rewardToken), recipients, rewards);
        cheats.stopPrank();
        uint256 reward1 = rewardToken.balanceOf(address(users[2]));
        uint256 reward2 = rewardToken.balanceOf(address(users[3]));
        uint256 reward3 = rewardToken.balanceOf(address(users[4]));
        console.logString("reward balances are ");
        console.logUint(reward1);
        console.logUint(reward2);
        console.logUint(reward3);
        // now test withdraw
        cheats.startPrank(address(users[0]));
        multiSender.withdrawToken(address(rewardToken), rewardToken.balanceOf(address(multiSender)), address(users[5]));
        uint256 withdrawnAmount = rewardToken.balanceOf(address(users[5]));
        console.logUint(withdrawnAmount);
    }
}