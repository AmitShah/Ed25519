// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;


interface IHashCastKarma {
    struct ClaimRequest {
        bytes32 pubkey; 
        bytes32 r; 
        bytes32 s;
    }

    struct TransferRequest {
        bytes32 pubkey;
        address to;
        uint256 value;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
    }
 
}
