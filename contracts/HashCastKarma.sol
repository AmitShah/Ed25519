// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";
pragma experimental ABIEncoderV2;

import "./libraries/Ed25519.sol";
import "hardhat/console.sol";

contract Karma is ERC20Base{
     bytes32 private immutable _PERMIT_EDDSA_TYPEHASH =
        keccak256("Permit(bytes32 pubkey,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(address _defaultAdmin, string memory _name, string memory _symbol) ERC20Base(_defaultAdmin,_name, _symbol) {        
    }

    function permitEDDSA(
        bytes32 pubkey,
        address spender,
        uint256 value,
        uint256 deadline,    
        bytes32 r,
        bytes32 s
    ) public  {
        address vaddress = Ed25519.getVirtualAddress(pubkey);
        require(block.timestamp <= deadline, "ERC20PermitEDDSA: expired deadline");
        bytes32 structHash = keccak256(abi.encode(_PERMIT_EDDSA_TYPEHASH, pubkey, spender, value, _useNonce(vaddress), deadline));
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR(), structHash);
        bool valid = Ed25519.verify(pubkey, r, s, abi.encodePacked(digest));       
        require(valid, "ERC20PermitEDDSA: invalid signature");
        _approve(vaddress, spender, value);
    }


}