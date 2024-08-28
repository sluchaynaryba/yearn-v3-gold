// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IPoolManager {
    function addPool(address _gauge) external returns (bool);

    function operator() external view returns (address);

    function pools() external view returns (address);

    function protectAddPool() external view returns (bool);

    function setOperator(address _operator) external;

    function setProtectPool(bool _protectAddPool) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;
}
