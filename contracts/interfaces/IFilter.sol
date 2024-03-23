// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;


interface IFilter {
    function filter(address vaddress) external pure returns (bool); 
}
