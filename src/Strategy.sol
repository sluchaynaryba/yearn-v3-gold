// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseStrategy, ERC20} from "@tokenized-strategy/BaseStrategy.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IVault} from "@balancer/interfaces/contracts/vault/IVault.sol";
import {WeightedPoolUserData} from "@balancer/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";
import {IAsset} from "@balancer/interfaces/contracts/vault/IAsset.sol";

import {IBaseRewardPool} from "../src/interfaces/aura/IBaseRewardPool.sol";
import {IStYeth} from "../src/interfaces/yearn/IStYeth.sol";
import {ICurveStablePool} from "../src/interfaces/curve/ICurveStablePool.sol";
import {IChainlink} from "../src/interfaces/chainlink/IChainlink.sol";
import {IWeightedOraclePool} from "../src/interfaces/balancer/IWeightedOraclePool.sol";

/// @title GoldenBoyzCompounderStrategy
/// @author GoldenBoyz
/// @notice yearn-v3 Strategy that invests BPT into Aura and autocompounds
contract GoldenBoyzCompounderStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    uint256 constant BPS = 10_000;

    IERC20 constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 constant BAL = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant YETH = IERC20(0x1BED97CBC3c24A4fb5C069C6E311a967386131f7);

    address constant GOLD = 0x9DeB0fc809955b79c85e82918E8586d3b7d2695a;

    IVault constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    IStYeth constant ST_YETH = IStYeth(0x583019fF0f430721aDa9cfb4fac8F06cA104d0B4);

    ICurveStablePool constant YETH_CURVE_POOL = ICurveStablePool(0x69ACcb968B19a53790f43e57558F5E443A91aF22);

    IWeightedOraclePool constant ORACLE_WEIGHTED_POOL = IWeightedOraclePool(0xc29562b045D80fD77c69Bec09541F5c16fe20d9d);
    IChainlink constant BAL_ETH_FEED = IChainlink(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);

    IBaseRewardPool public rewardsContract;

    uint256 public slippBalToWeth;
    uint256 public slippAuraToWeth;
    uint256 public slippWethToYeth;
    uint256 public oracleWeightedPoolTimeWindow;
    uint256 public curveOracleTimeWindow;

    constructor(address _asset, address _rewardsContract) BaseStrategy(_asset, "GoldenBoyzCompounderStrategy") {
        asset.approve(_rewardsContract, type(uint256).max);
        rewardsContract = IBaseRewardPool(_rewardsContract);
        if (rewardsContract.asset() != _asset) revert("Invalid rewards contract");

        slippBalToWeth = 9_800;
        slippAuraToWeth = 9_800;
        slippWethToYeth = 9_970;
        oracleWeightedPoolTimeWindow = 1 hours;
        curveOracleTimeWindow = 1 days; // @audit on deployment advisable to be 24 hours

        BAL.approve(address(BALANCER_VAULT), type(uint256).max);
        AURA.approve(address(BALANCER_VAULT), type(uint256).max);
        ST_YETH.approve(address(BALANCER_VAULT), type(uint256).max);
        WETH.approve(address(YETH_CURVE_POOL), type(uint256).max);
        YETH.approve(address(ST_YETH), type(uint256).max);
    }

    function setSlippBalToWeth(uint256 _slippBalToWeth) external onlyManagement {
        slippBalToWeth = _slippBalToWeth;
    }

    function setSlippAuraToWeth(uint256 _slippAuraToWeth) external onlyManagement {
        slippAuraToWeth = _slippAuraToWeth;
    }

    function setSlippWethToYeth(uint256 _slippWethToYeth) external onlyManagement {
        slippWethToYeth = _slippWethToYeth;
    }

    function setOracleWeightedPoolTimeWindow(uint256 _oracleWeightedPoolTimeWindow) external onlyManagement {
        oracleWeightedPoolTimeWindow = _oracleWeightedPoolTimeWindow;
    }

    function setCurveOracleTimeWindow(uint256 _curveOracleTimeWindow) external onlyManagement {
        curveOracleTimeWindow = _curveOracleTimeWindow;
    }

    function _deployFunds(uint256 _amount) internal override {
        rewardsContract.deposit(_amount, address(this));
    }

    function _freeFunds(uint256 _amount) internal override {
        rewardsContract.withdrawAndUnwrap(_amount, false);
    }

    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        if (!TokenizedStrategy.isShutdown()) {
            rewardsContract.getReward();

            uint256 balancerB = BAL.balanceOf(address(this));
            if (balancerB > 0) {
                _balancerToWethSwap(balancerB);

                uint256 auraB = AURA.balanceOf(address(this));
                if (auraB > 0) {
                    _auraToWethSwap(auraB);
                }

                uint256 wethB = WETH.balanceOf(address(this));
                if (wethB > 0) {
                    _wethToYethSwap(wethB);
                }

                uint256 yethB = YETH.balanceOf(address(this));
                if (yethB > 0) {
                    _stakeYeth(yethB);
                    _singleSidedYethDepositBpt(ST_YETH.balanceOf(address(this)));
                    _deployFunds(asset.balanceOf(address(this)));
                }
            }
        }

        // idle + staked
        _totalAssets = asset.balanceOf(address(this)) + rewardsContract.balanceOf(address(this));
    }

    /// @notice Allows management to manually pull funds from the yield source once a strategy has been shut down
    /// @param _amount Amount of the asset to withdraw from yield source
    function _emergencyWithdraw(uint256 _amount) internal override {
        _amount = Math.min(_amount, rewardsContract.balanceOf(address(this)));
        _freeFunds(_amount);
    }

    /// @notice Scales the amount of BAL to WETH using the oracle
    /// @param _balancerAmount Amount of BAL to scale
    function _balToEtHOracleScale(uint256 _balancerAmount) internal view returns (uint256) {
        (, int256 answer,, uint256 ts,) = BAL_ETH_FEED.latestRoundData();
        if (answer < 0) revert("Chainlink price is negative");
        if (block.timestamp - ts > 24 hours) revert("Chainlink price is outdated");
        return uint256(answer) * _balancerAmount / 1e18;
    }

    /// @notice Swaps BAL to WETH using Balancer
    function _balancerToWethSwap(uint256 _amount) internal {
        BALANCER_VAULT.swap(
            IVault.SingleSwap({
                poolId: 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(BAL)),
                assetOut: IAsset(address(WETH)),
                amount: _amount,
                userData: ""
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            _balToEtHOracleScale(_amount) * slippBalToWeth / BPS,
            block.timestamp
        );
    }

    /// @notice Scales the amount of AURA to WETH using the oracle weighted pool
    /// @param _auraAmount Amount of AURA to scale
    function _auraToEthOracleWeightedPoolScale(uint256 _auraAmount) internal view returns (uint256) {
        IWeightedOraclePool.OracleAverageQuery[] memory q = new IWeightedOraclePool.OracleAverageQuery[](1);
        q[0] = IWeightedOraclePool.OracleAverageQuery({variable: 0, secs: oracleWeightedPoolTimeWindow, ago: 0});
        return (_auraAmount * ORACLE_WEIGHTED_POOL.getTimeWeightedAverage(q)[0]) / 1e18;
    }

    /// @notice Swaps AURA to WETH using Balancer
    function _auraToWethSwap(uint256 _amount) internal {
        BALANCER_VAULT.swap(
            IVault.SingleSwap({
                poolId: 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(AURA)),
                assetOut: IAsset(address(WETH)),
                amount: _amount,
                userData: ""
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            _auraToEthOracleWeightedPoolScale(_amount) * slippAuraToWeth / BPS,
            block.timestamp
        );
    }

    /// @notice Scales the amount of WETH to YETH
    /// @param _wethAmount Amount of WETH to scale
    function _wethToYethScale(uint256 _wethAmount) internal returns (uint256) {
        if (block.timestamp - YETH_CURVE_POOL.ma_last_time() > curveOracleTimeWindow) {
            revert("Curve oracle is outdated");
        }
        return (_wethAmount * 1e18) / YETH_CURVE_POOL.price_oracle();
    }

    /// @notice Swaps WETH to YETH using Curve
    function _wethToYethSwap(uint256 _amount) internal {
        YETH_CURVE_POOL.exchange(0, 1, _amount, _wethToYethScale(_amount) * slippWethToYeth / BPS);
    }

    /// @notice Stakes YETH in ST-YETH
    function _stakeYeth(uint256 _amount) internal {
        ST_YETH.deposit(_amount);
    }

    /// @notice Deposits ST-YETH into Balancer single-sided
    /// @param _singleSideYethAmount Amount of ST-YETH to deposit
    function _singleSidedYethDepositBpt(uint256 _singleSideYethAmount) internal {
        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = _singleSideYethAmount;

        IAsset[] memory assets = new IAsset[](2);
        assets[0] = IAsset(address(ST_YETH));
        assets[1] = IAsset(IAsset(GOLD));

        IVault.JoinPoolRequest memory joinRequest = IVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, 0),
            fromInternalBalance: false
        });

        BALANCER_VAULT.joinPool(
            0xcf8dfdb73e7434b05903b5599fb96174555f43530002000000000000000006c3,
            address(this),
            address(this),
            joinRequest
        );
    }
}
