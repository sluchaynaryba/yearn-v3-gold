// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ICurveStablePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external returns (uint256);

    function ma_last_time() external view returns (uint256);

    function price_oracle() external view returns (uint256);
}
