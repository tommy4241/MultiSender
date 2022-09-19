// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("TestRewardToken", "TRT") {}

    function mint(address _a, uint256 _b) public {
        _mint(_a, _b);
    }
}
