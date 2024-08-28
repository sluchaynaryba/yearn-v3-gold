// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IStYeth {
    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address _account) external view returns (uint256);

    function deposit(uint256 _assets) external returns (uint256);
}
