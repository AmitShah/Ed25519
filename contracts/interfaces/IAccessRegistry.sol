// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;


interface IAccessRegistry {
    
    struct AddFilter {
        bytes32 pubkey;
        address filter;
        bytes32 r;
        bytes32 s;
        bytes message;
    }
 
}
