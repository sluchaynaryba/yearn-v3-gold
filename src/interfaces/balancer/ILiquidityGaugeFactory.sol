// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ILiquidityGaugeFactory {
    event GaugeCreated(address indexed gauge);

    function create(address pool, uint256 relativeWeightCap) external returns (address);

    function getGaugeImplementation() external view returns (address);

    function isGaugeFromFactory(address gauge) external view returns (bool);
}
