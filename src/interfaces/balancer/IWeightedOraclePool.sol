// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IWeightedOraclePool {
    struct OracleAverageQuery {
        uint8 variable;
        uint256 secs;
        uint256 ago;
    }

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);
}
