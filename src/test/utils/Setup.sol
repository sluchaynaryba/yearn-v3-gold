// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/console2.sol";
import {ExtendedTest} from "./ExtendedTest.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GoldenBoyzCompounderStrategy, ERC20} from "../../Strategy.sol";
import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";

import {IEvents} from "@tokenized-strategy/interfaces/IEvents.sol";

import {TokenizedStrategy} from "@tokenized-strategy/TokenizedStrategy.sol";
import {MockFactory} from "@tokenized-strategy/test/mocks/MockFactory.sol";

import {IStakingLiquidityGauge} from "@balancer/interfaces/contracts/liquidity-mining/IStakingLiquidityGauge.sol";

import {ILiquidityGaugeFactory} from "../../interfaces/balancer/ILiquidityGaugeFactory.sol";
import {IGaugeController} from "../../interfaces/balancer/IGaugeController.sol";
import {IWeightedPoolFactory} from "../../interfaces/balancer/IWeightedPoolFactory.sol";
import {IPoolManager} from "../../interfaces/aura/IPoolManager.sol";
import {IBooster} from "../../interfaces/aura/IBooster.sol";
import {IChainlink} from "../../interfaces/chainlink/IChainlink.sol";
import {ICurveStablePool} from "../../interfaces/curve/ICurveStablePool.sol";
import {IWeightedOraclePool} from "../../interfaces/balancer/IWeightedOraclePool.sol";

interface IFactory {
    function governance() external view returns (address);

    function set_protocol_fee_bps(uint16) external;

    function set_protocol_fee_recipient(address) external;
}

contract Setup is ExtendedTest, IEvents {
    struct StrategySnapshot {
        uint256 totalAssetValue;
        uint256 totalLiquidBalance;
    }

    ERC20 constant BPT_WANT_ASSET = ERC20(0xcF8dFdb73e7434b05903B5599fB96174555F4353);

    IERC20 constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 constant BAL = IERC20(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant YETH = IERC20(0x1BED97CBC3c24A4fb5C069C6E311a967386131f7);

    address constant GOLD_TOKEN = 0x9DeB0fc809955b79c85e82918E8586d3b7d2695a;
    address constant ST_YETH_TOKEN = 0x583019fF0f430721aDa9cfb4fac8F06cA104d0B4;

    address constant BALANCER_AUTH_ADAPTOR = 0x8F42aDBbA1B16EaAE3BB5754915E0D06059aDd75;
    IWeightedPoolFactory constant BALANCER_WEIGHTED_POOL_FACTORY_V4 =
        IWeightedPoolFactory(0x897888115Ada5773E02aA29F775430BFB5F34c51);
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    ILiquidityGaugeFactory constant BALANCER_GAUGE_FACTORY =
        ILiquidityGaugeFactory(0xf1665E19bc105BE4EDD3739F88315cC699cc5b65);
    IGaugeController constant BALANCER_GAUGE_CONTROLLER = IGaugeController(0xC128468b7Ce63eA702C1f104D55A2566b13D3ABD);

    IPoolManager constant AURA_POOL_MANAGER = IPoolManager(0x8Dd8cDb1f3d419CCDCbf4388bC05F4a7C8aEBD64);
    IBooster constant AURA_BOSTER = IBooster(0xA57b8d98dAE62B26Ec3bcC4a365338157060B234);

    IWeightedOraclePool constant ORACLE_WEIGHTED_POOL = IWeightedOraclePool(0xc29562b045D80fD77c69Bec09541F5c16fe20d9d);

    IChainlink constant BAL_ETH_FEED = IChainlink(0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b);
    ICurveStablePool constant YETH_CURVE_POOL = ICurveStablePool(0x69ACcb968B19a53790f43e57558F5E443A91aF22);

    // Contract instances that we will use repeatedly.
    ERC20 public asset;
    IStrategyInterface public strategy;

    mapping(string => address) public tokenAddrs;

    // Addresses for different roles we will use repeatedly.
    address public user = address(10);
    address public keeper = address(4);
    address public management = address(1);
    address public performanceFeeRecipient = address(3);
    address public adminWallet = address(111);
    address public devopsWallet = address(222);

    // Address of the real deployed Factory
    address public factory;

    // Integer variables that will be used repeatedly.
    uint256 public decimals;
    uint256 public MAX_BPS = 10_000;

    // Fuzz from $0.01 of 1e6 stable coins up to 1 trillion of a 1e18 coin
    uint256 public maxFuzzAmount = 1e30;
    uint256 public minFuzzAmount = 10_000;

    // Default profit max unlock time is set for 10 days
    uint256 public profitMaxUnlockTime = 10 days;

    MockFactory internal mockFactory;

    TokenizedStrategy internal tokenizedStrategy;

    function setUp() public virtual {
        _setUp(BPT_WANT_ASSET);
    }

    function _setUp(ERC20 _underlying) internal {
        // set asset
        asset = _underlying;

        // set decimals
        decimals = asset.decimals();

        mockFactory = new MockFactory(0, address(0));

        // factory from mainnet, tokenized strategy needs to be hardcoded to 0xBB51273D6c746910C7C06fe718f30c936170feD0
        tokenizedStrategy = new TokenizedStrategy(address(mockFactory));
        vm.etch(0xBB51273D6c746910C7C06fe718f30c936170feD0, address(tokenizedStrategy).code);

        // enable gauge & aura pid
        address baseRewardPoolAura = _createGaugeAndAuraRewardPool(address(BPT_WANT_ASSET));

        // deploy strategy and set variables
        strategy = IStrategyInterface(setUpStrategy(baseRewardPoolAura));

        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        vm.label(factory, "factory");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
        vm.label(address(strategy), "GoldenBoyzCompounderStrategy");

        vm.label(address(BPT_WANT_ASSET), "BPT_WANT_ASSET");
        vm.label(BALANCER_VAULT, "BALANCER_VAULT");
        vm.label(address(BALANCER_GAUGE_CONTROLLER), "BALANCER_GAUGE_CONTROLLER");

        vm.label(address(AURA_POOL_MANAGER), "AURA_POOL_MANAGER");
        vm.label(baseRewardPoolAura, "baseRewardPoolAura");

        vm.label(address(YETH_CURVE_POOL), "YETH_CURVE_POOL");

        vm.label(address(ORACLE_WEIGHTED_POOL), "ORACLE_WEIGHTED_POOL");
        vm.label(address(BAL_ETH_FEED), "BAL_ETH_FEED");

        vm.label(GOLD_TOKEN, "GOLD_TOKEN");
        vm.label(ST_YETH_TOKEN, "ST_YETH_TOKEN");
        vm.label(address(BAL), "BAL");
        vm.label(address(AURA), "AURA");
        vm.label(address(WETH), "WETH");
        vm.label(address(YETH), "YETH");
    }

    function setUpStrategy(address _baseRewardPoolAura) public returns (address) {
        IStrategyInterface _strategy =
            IStrategyInterface(address(new GoldenBoyzCompounderStrategy(address(asset), _baseRewardPoolAura)));

        // set keeper
        _strategy.setKeeper(keeper);
        // set treasury
        _strategy.setPerformanceFeeRecipient(performanceFeeRecipient);
        // set management of the strategy
        _strategy.setPendingManagement(management);

        vm.prank(management);
        _strategy.acceptManagement();

        return address(_strategy);
    }

    function depositIntoStrategy(IStrategyInterface _strategy, address _user, uint256 _amount) public {
        vm.prank(_user);
        asset.approve(address(_strategy), _amount);

        vm.prank(_user);
        _strategy.deposit(_amount, _user);
    }

    function mintAndDepositIntoStrategy(IStrategyInterface _strategy, address _user, uint256 _amount) public {
        airdrop(asset, _user, _amount);
        depositIntoStrategy(_strategy, _user, _amount);
    }

    // For checking the amounts in the strategy
    function checkStrategyTotals(
        IStrategyInterface _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle
    ) public {
        uint256 _assets = _strategy.totalAssets();
        uint256 _balance = ERC20(_strategy.asset()).balanceOf(address(_strategy));
        uint256 _idle = _balance > _assets ? _assets : _balance;
        uint256 _debt = _assets - _idle;
        assertEq(_assets, _totalAssets, "!totalAssets");
        assertEq(_debt, _totalDebt, "!totalDebt");
        assertEq(_idle, _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
    }

    function airdrop(ERC20 _asset, address _to, uint256 _amount) public {
        uint256 balanceBefore = _asset.balanceOf(_to);
        deal(address(_asset), _to, balanceBefore + _amount);
    }

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        address gov = IFactory(factory).governance();

        // Need to make sure there is a protocol fee recipient to set the fee.
        vm.prank(gov);
        IFactory(factory).set_protocol_fee_recipient(gov);

        vm.prank(gov);
        IFactory(factory).set_protocol_fee_bps(_protocolFee);

        vm.prank(management);
        strategy.setPerformanceFee(_performanceFee);
    }

    function _createGaugeAndAuraRewardPool(address _bpt) internal returns (address) {
        // gauge creation 10% cap
        address gauge = BALANCER_GAUGE_FACTORY.create(_bpt, 0.1e18);

        // send 1k BAL to gauge
        deal(address(BAL), gauge, 1000e18);

        // send gauge token to voter proxy
        deal(address(BPT_WANT_ASSET), AURA_BOSTER.staker(), 1000e18);
        vm.startPrank(AURA_BOSTER.staker());
        BPT_WANT_ASSET.approve(gauge, 1000e18);
        IStakingLiquidityGauge(gauge).deposit(1000e18, AURA_BOSTER.staker());
        vm.stopPrank();

        // add gauge and >0 gauge weight
        vm.prank(BALANCER_AUTH_ADAPTOR);
        BALANCER_GAUGE_CONTROLLER.add_gauge(gauge, 2, 0.1e18);

        // aura reward pool
        vm.prank(AURA_POOL_MANAGER.operator());
        AURA_POOL_MANAGER.addPool(gauge);
        uint256 pid = AURA_BOSTER.poolLength() - 1;
        (address lptoken,,, address crvRewards,,) = AURA_BOSTER.poolInfo(pid);
        assertEq(lptoken, _bpt);
        _earmarkRewards(pid);
        return crvRewards;
    }

    function _earmarkRewards(uint256 _pid) internal {
        vm.prank(keeper);
        assertTrue(AURA_BOSTER.earmarkRewards(_pid));
    }

    function _syncOracleTimestamp(uint256 _time) internal {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 ts, uint80 answeredInRound) =
            BAL_ETH_FEED.latestRoundData();
        vm.mockCall(
            address(BAL_ETH_FEED),
            abi.encodeWithSelector(IChainlink.latestRoundData.selector),
            abi.encode(roundId, answer, startedAt, ts + _time, answeredInRound)
        );
    }

    function _syncCurveOracleMaLastTime(uint256 _time) internal {
        uint256 maLastTimeUpdated = YETH_CURVE_POOL.ma_last_time();
        maLastTimeUpdated = block.timestamp - maLastTimeUpdated > 1 days ? block.timestamp : maLastTimeUpdated + _time;
        vm.mockCall(
            address(YETH_CURVE_POOL),
            abi.encodeWithSelector(ICurveStablePool.ma_last_time.selector),
            abi.encode(maLastTimeUpdated)
        );
    }
}
