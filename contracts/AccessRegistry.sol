// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/cryptography/EIP712.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./libraries/Ed25519.sol";
import "hardhat/console.sol";
import "./interfaces/IHashCastKarma.sol";
import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/Counters.sol";
import "./interfaces/IFilter.sol";
import "./interfaces/IKeyRegistry.sol";

pragma experimental ABIEncoderV2;

contract AccessRegistry is EIP712, Ownable{
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _nonces;
    mapping(address=>IFilter) _filters;
    IKeyRegistry private _keyRegistry;

    constructor(address _keyRegistryAddress)  EIP712("AccessRegistry", "1.0.0") {
        _setupOwner(msg.sender);
        _keyRegistry = IKeyRegistry(_keyRegistryAddress);
    }

     /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }

    function _useNonce(address owner) internal returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
  
    function getVirtualAddress(bytes32 pubkey) public pure returns(address){
        return  Ed25519.getVirtualAddress(pubkey);
    }

    function addFilter(IHashCastKarma.ClaimRequest calldata c) public {
        address vaddress = Ed25519.getVirtualAddress(c.pubkey);
        uint256 nonce = _useNonce(vaddress);    
        uint256 fid = 0; //this should be in the passed messagedata proto buf   
        IKeyRegistry.KeyData memory kd = _keyRegistry.keyDataOf(fid, abi.encodePacked(c.pubkey));
        require(kd.state == IKeyRegistry.KeyState.ADDED, "");

        bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
            //TODO: need replay protection on the struct
          keccak256("Claim(address from,uint256 nonce)"),
          vaddress,nonce))));

        bool valid = Ed25519.verify(c.pubkey, c.r, c.s, digest);
        require(valid,"invalid signature");

        //set the cast hash to use the filter
        _filters[vaddress] = IFilter(address(0)); 
    }


    function removeFilter() public{

    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
        /// @dev Emitted when tokens are minted with `mintTo`
    event TokensMinted(address indexed mintedTo, uint256 quantityMinted);
    function mintTo(address to, uint256 amount) external;
    function transferWithAuthorization(
        bytes32 pubkey,
        address to,
        uint256 value,
        uint256 deadline,
        bytes32 r,
        bytes32 s
    ) external;
}
