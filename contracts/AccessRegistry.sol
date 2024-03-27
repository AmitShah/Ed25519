// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/cryptography/EIP712.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./libraries/Ed25519.sol";
import "./libraries/Blake3.sol";
import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/Counters.sol";
import "./interfaces/IFilter.sol";
import "./interfaces/IKeyRegistry.sol";
import "./interfaces/IAccessRegistry.sol";
import "./protobufs/message.proto.sol";
// import "hardhat/console.sol";

pragma experimental ABIEncoderV2;



contract AccessRegistry is EIP712, Ownable{    
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _nonces;
    mapping(address=>address) _filters;
    mapping(address=>bytes32[]) _privateCastMembers;
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

    function addFilter(
        IAccessRegistry.AddFilter calldata f
    ) external {
    address vaddress = Ed25519.getVirtualAddress(f.pubkey);
    uint256 nonce = _useNonce(vaddress);       
    bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
        keccak256("AddFilter(address from,address filter,uint256 nonce)"),
        vaddress,f.filter,nonce))));

    bool valid = Ed25519.verify(f.pubkey, f.r, f.s, digest);
    require(valid,"invalid signature");

    (MessageData memory message_data, bytes memory hash) = _verifyMessage(
      f.message
    );

    IKeyRegistry.KeyData memory kd =  _keyRegistry.keyDataOf(message_data.fid, abi.encodePacked(f.pubkey));
    require(kd.state==IKeyRegistry.KeyState.ADDED,"key unassigned");
    
    address castAddress;
    assembly {
      castAddress := mload(add(hash,20))
    } 

    _filters[castAddress] = address(0x1);
  }

    function _verifyMessage(
        bytes memory message
    ) internal pure returns(MessageData memory, bytes memory) {
    // Calculate Blake3 hash of FC message (first 20 bytes)
    bytes memory message_hash = Blake3.hash(message, 20);  

    (
      bool success,
      ,
      MessageData memory message_data
    ) = MessageDataCodec.decode(0, message, uint64(message.length));

    if (!success) {
      revert();
    }

    return (message_data,message_hash);
  }

  function getPrivateCastMembers(address casthash) public view returns (bytes32[] memory) {
        bytes32[] memory members = _privateCastMembers[casthash];
        return members;
    }

    function joinPrivateCast(address casthash,bytes32 pubkey, bytes32 r, bytes32 s) external {
        address vaddress = Ed25519.getVirtualAddress(pubkey);
        address filter = _filters[casthash];
        if(filter !=address(0)){
         (bool success, bytes memory returnBytes) = filter.staticcall(abi.encodeWithSignature("access(address vaddress)",vaddress));
         require(success == true, "Call to access(address vaddress) failed");
         bool canAccess = abi.decode(returnBytes, (bool));
         require(canAccess == true , "user cannot join cast");
      }

       uint256 nonce = _useNonce(vaddress);       
        bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
            keccak256("JoinCast(address casthash,address vaddress,uint256 nonce)"),
            casthash,vaddress,nonce))));

        bool valid = Ed25519.verify(pubkey, r, s, digest);
        require(valid,"invalid signature");
      //add user as part of membership table
      _privateCastMembers[casthash].push(pubkey);
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
