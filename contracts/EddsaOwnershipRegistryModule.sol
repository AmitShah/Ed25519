// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@biconomy-devx/account-contracts/contracts/smart-account/modules/BaseAuthorizationModule.sol";
import "./libraries/Ed25519.sol";
import "hardhat/console.sol";

/**
 * @title ECDSA ownership Authorization module for Biconomy Smart Accounts.
 * @dev Compatible with Biconomy Modular Interface v 0.1
 *         - It allows to validate user operations signed by EOA private key.
 *         - EIP-1271 compatible (ensures Smart Account can validate signed messages).
 *         - One owner per Smart Account.
 *         - Does not support outdated eth_sign flow for cheaper validations
 *         (see https://support.metamask.io/hc/en-us/articles/14764161421467-What-is-eth-sign-and-why-is-it-a-risk-)
 * !!!!!!! Only EOA owners supported, no Smart Account Owners
 *         For Smart Contract Owners check SmartContractOwnership module instead
 * @author Fil Makarov - <filipp.makarov@biconomy.io>
 */

contract EddsaOwnershipRegistryModule is BaseAuthorizationModule {
    

    string public constant NAME = "EDDSA Ownership Registry Module";
    string public constant VERSION = "0.0.0";
    mapping(address => bytes32) internal _smartAccountOwners;

    event OwnershipTransferred(
        address indexed smartAccount,
        bytes32 indexed oldOwner,
        bytes32 indexed newOwner
    );

    error NoOwnerRegisteredForSmartAccount(address smartAccount);
    error AlreadyInitedForSmartAccount(address smartAccount);
    error WrongSignatureLength();
    error NotEOA(address account);
    error ZeroAddressNotAllowedAsOwner();

    /**
     * @dev Initializes the module for a Smart Account.
     * Should be used at a time of first enabling the module for a Smart Account.
     * @param eoaOwner The owner of the Smart Account. Should be EOA!
     */
    function initForSmartAccount(bytes32 eoaOwner) external returns (address) {
        if (_smartAccountOwners[msg.sender] != bytes32(0))
            revert AlreadyInitedForSmartAccount(msg.sender);
        if (eoaOwner == bytes32(0)) revert ZeroAddressNotAllowedAsOwner();
        _smartAccountOwners[msg.sender] = eoaOwner;
        return address(this);
    }

    /**
     * @dev Sets/changes an for a Smart Account.
     * Should be called by Smart Account itself.
     * @param owner The owner of the Smart Account.
     */
    function transferOwnership(address owner) external {
        // if (_isSmartContract(owner)) revert NotEOA(owner);
        // if (owner == address(0)) revert ZeroAddressNotAllowedAsOwner();
        // _transferOwnership(msg.sender, owner);
    }

    /**
     * @dev Renounces ownership
     * should be called by Smart Account.
     */
    function renounceOwnership() external {
        return;
    }

    /**
     * @dev Returns the owner of the Smart Account. Reverts for Smart Accounts without owners.
     * @param smartAccount Smart Account address.
     * @return owner The owner of the Smart Account.
     */
    function getOwner(address smartAccount) external view returns (bytes32) {
        bytes32 owner = _smartAccountOwners[smartAccount];
        if (owner == bytes32(0))
            revert NoOwnerRegisteredForSmartAccount(smartAccount);
        return owner;
    }

    /**
     * @dev validates userOperation
     * @param userOp User Operation to be validated.
     * @param userOpHash Hash of the User Operation to be validated.
     * @return sigValidationResult 0 if signature is valid, SIG_VALIDATION_FAILED otherwise.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view virtual returns (uint256) {
        console.logBytes(userOp.signature);
        
        if (_verifySignature(userOpHash, userOp.signature, userOp.sender)) {
            return VALIDATION_SUCCESS;
        }
        return SIG_VALIDATION_FAILED;
    }

    /**
     * @dev Validates a signature for a message.
     * To be called from a Smart Account.
     * @param dataHash Exact hash of the data that was signed.
     * @param moduleSignature Signature to be validated.
     * @return EIP1271_MAGIC_VALUE if signature is valid, 0xffffffff otherwise.
     */
    function isValidSignature(
        bytes32 dataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        return
            isValidSignatureForAddress(dataHash, moduleSignature, msg.sender);
    }

    /**
     * @dev Validates a signature for a message signed by address.
     * @dev Also try dataHash.toEthSignedMessageHash()
     * @param dataHash hash of the data
     * @param moduleSignature Signature to be validated.
     * @param smartAccount expected signer Smart Account address.
     * @return EIP1271_MAGIC_VALUE if signature is valid, 0xffffffff otherwise.
     */
    function isValidSignatureForAddress(
        bytes32 dataHash,
        bytes memory moduleSignature,
        address smartAccount
    ) public view virtual returns (bytes4) {
        if (_verifySignature(dataHash, moduleSignature, smartAccount)) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }

    /**
     * @dev Transfers ownership for smartAccount and emits an event
     * @param newOwner Smart Account address.
     */
    function _transferOwnership(
        address smartAccount,
        bytes32 newOwner
    ) internal {
        bytes32 _oldOwner = _smartAccountOwners[smartAccount];
        _smartAccountOwners[smartAccount] = newOwner;
        emit OwnershipTransferred(smartAccount, _oldOwner, newOwner);
    }

    /**
     * @dev Validates a signature for a message.
     * @dev Check if signature was made over dataHash.toEthSignedMessageHash() or just dataHash
     * The former is for personal_sign, the latter for the typed_data sign
     * Only EOA owners supported, no Smart Account Owners
     * For Smart Contract Owners check SmartContractOwnership Module instead
     * @param dataHash Hash of the data to be validated.
     * @param signature Signature to be validated.
     * @param smartAccount expected signer Smart Account address.
     * @return true if signature is valid, false otherwise.
     */
    function _verifySignature(
        bytes32 dataHash,
        bytes memory signature,
        address smartAccount
    ) internal view returns (bool) {
        bytes32 expectedSigner = _smartAccountOwners[smartAccount];
        if (expectedSigner == bytes32(0))
            revert NoOwnerRegisteredForSmartAccount(smartAccount);
        // if (signature.length < 65) revert WrongSignatureLength();
        // address recovered = (dataHash.toEthSignedMessageHash()).recover(
        //     signature
        // );
        // if (expectedSigner == recovered) {
        //     return true;
        // }
        // recovered = dataHash.recover(signature);
        // if (expectedSigner == recovered) {
        //     return true;
        // }
        
        (bytes32 r, bytes32 s ) = abi.decode(
            signature,
            (bytes32, bytes32)
        );
        console.logBytes32(expectedSigner);
        console.logBytes32(r);
        console.logBytes32(s);
        console.logBytes(abi.encodePacked(dataHash));
        return Ed25519.verify(expectedSigner, r, s, abi.encodePacked(dataHash));
    }

    /**
     * @dev Checks if the address provided is a smart contract.
     * @param account Address to be checked.
     */
    function _isSmartContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}