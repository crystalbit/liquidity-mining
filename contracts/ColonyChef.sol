// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


// Forked from SUSHI MasterChef
contract ColonyChef is Ownable {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward token
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address. - UPD only for withdraw
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }


    IERC20 public lpToken;
    uint256 public lastRewardTime;
    uint256 public accRewardPerShare; // Accumulated RewardToken per share, times 1e12
    IERC20 public rewardToken;
    address public rewardPool;
    uint256 public rewardPerSecond;
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SetRewardPerSecond(uint256 amount);

    constructor(
        IERC20 _rewardToken,
        IERC20 _lpToken,
        address _rewardPool,
        uint256 _rewardPerSecond,
        uint256 _startTime
    ) {
        rewardToken = _rewardToken;
        lpToken = _lpToken;
        rewardPool = _rewardPool;
        rewardPerSecond = _rewardPerSecond;
        // The time when reward token distribution starts.
        lastRewardTime = _startTime;
    }

    // View function to see pending reward tokens on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 lpSupply = lpToken.balanceOf(address(this));
        uint256 _accRewardPerShare = accRewardPerShare;
        if (block.timestamp > lastRewardTime && lpSupply != 0) {
            uint256 reward = (block.timestamp - lastRewardTime) * rewardPerSecond;
            _accRewardPerShare = _accRewardPerShare + reward * 1e12 / lpSupply;
        }
        return user.amount * _accRewardPerShare / 1e12 - user.rewardDebt;
    }

    // Update reward variables to be up-to-date.
    function updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 reward = (block.timestamp - lastRewardTime) * rewardPerSecond;
        accRewardPerShare = accRewardPerShare + reward * 1e12 / lpSupply;
        lastRewardTime = block.timestamp;
        rewardToken.safeTransferFrom(address(rewardPool), address(this), reward);
    }

    // Deposit LP tokens to ColonyChef for reward token allocation.
    function deposit(uint256 _amount) external {
        require(_amount > 0, 'zero deposit');
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        }
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * accRewardPerShare / 1e12 - pending;
        lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from ColonyChef.
    // any withdraw send all harvest to the user, so withdraw(0) - just collect harvest
    function withdraw(uint256 _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, 'withdraw: not good');
        updatePool();
        uint256 pending = user.amount * accRewardPerShare / 1e12 - user.rewardDebt;
        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * accRewardPerShare / 1e12;
        safeRewardTransfer(msg.sender, pending);
        lpToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function changeRewardPerSecond(uint256 newSpeed) external onlyOwner {
        updatePool();
        rewardPerSecond = newSpeed;
        emit SetRewardPerSecond(newSpeed);
    }

    function changeRewardPool(address _address) external onlyOwner {
      rewardPool = _address;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    // safeRewardTransfer transfer function, just in case if pool doesn't have enough reward token.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        bool result = false;
        if (_amount > rewardBal) {
            result = rewardToken.transfer(_to, rewardBal);
        } else {
            result = rewardToken.transfer(_to, _amount);
        }
        require(result, 'transfer failed');
    }
}
