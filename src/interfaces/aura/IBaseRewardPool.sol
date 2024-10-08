// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IBaseRewardPool {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
    event Withdrawn(address indexed user, uint256 amount);

    function addExtraReward(address _reward) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function clearExtraRewards() external;

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function duration() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function historicalRewards() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function name() external view returns (string memory);

    function newRewardRatio() external view returns (uint256);

    function operator() external view returns (address);

    function periodFinish() external view returns (uint256);

    function pid() external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    function processIdleRewards() external;

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function queuedRewards() external view returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingToken() external view returns (address);

    function symbol() external view returns (string memory);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);

    function withdrawAll(bool claim) external;

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}
