// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ChefInterface {
  function rewardPerSecond() external view returns (uint256);
}
