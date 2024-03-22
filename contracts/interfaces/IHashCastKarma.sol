// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;


interface IHashCastKarma {
    struct ClaimRequest {
        address from;
        bytes32 k; 
        bytes32 r; 
        bytes32 s;
        uint256 nonce;
    }

    struct TransferRequest {
        address from;
        address to;
        uint256 amount;
        bytes32 k; 
        bytes32 r; 
        bytes32 s;
        uint256 nonce;
    }

 
}
