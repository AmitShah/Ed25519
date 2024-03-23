// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IKeyRegistry {
   
    enum KeyState {
        NULL,
        ADDED,
        REMOVED
    }

    /**
     *  @notice Data about a key.
     *
     *  @param state   The current state of the key.
     *  @param keyType Numeric ID representing the manner in which the key should be used.
     */
    struct KeyData {
        KeyState state;
        uint32 keyType;
    }

 

    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Contract version specified in the Farcaster protocol version scheme.
     */
    function VERSION() external view returns (string memory);

    /**
     * @notice EIP-712 typehash for Remove signatures.
     */
    function REMOVE_TYPEHASH() external view returns (bytes32);

   
    /*//////////////////////////////////////////////////////////////
                                  VIEWS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Return number of active keys for a given fid.
     *
     * @param fid the fid associated with the keys.
     *
     * @return uint256 total number of active keys associated with the fid.
     */
    function totalKeys(uint256 fid, KeyState state) external view returns (uint256);

    /**
     * @notice Return key at the given index in the fid's key set. Can be
     *         called to enumerate all active keys for a given fid.
     *
     * @param fid   the fid associated with the key.
     * @param index index of the key in the fid's key set. Must be a value
     *              less than totalKeys(fid). Note that because keys are
     *              stored in an underlying enumerable set, the ordering of
     *              keys is not guaranteed to be stable.
     *
     * @return bytes Bytes of the key.
     */
    function keyAt(uint256 fid, KeyState state, uint256 index) external view returns (bytes memory);

    /**
     * @notice Return an array of all active keys for a given fid.
     * @dev    WARNING: This function will copy the entire key set to memory,
     *         which can be quite expensive. This is intended to be called
     *         offchain with eth_call, not onchain.
     *
     * @param fid the fid associated with the keys.
     *
     * @return bytes[] Array of all keys.
     */
    function keysOf(uint256 fid, KeyState state) external view returns (bytes[] memory);

    /**
     * @notice Return an array of all active keys for a given fid,
     *         paged by index and batch size.
     *
     * @param fid       The fid associated with the keys.
     * @param startIdx  Start index of lookup.
     * @param batchSize Number of items to return.
     *
     * @return page    Array of keys.
     * @return nextIdx Next index in the set of all keys.
     */
    function keysOf(
        uint256 fid,
        KeyState state,
        uint256 startIdx,
        uint256 batchSize
    ) external view returns (bytes[] memory page, uint256 nextIdx);

    /**
     * @notice Retrieve state and type data for a given key.
     *
     * @param fid   The fid associated with the key.
     * @param key   Bytes of the key.
     *
     * @return KeyData struct that contains the state and keyType.
     */
    function keyDataOf(uint256 fid, bytes calldata key) external view returns (KeyData memory);

}