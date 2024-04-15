// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./libraries/Blake3.sol";
import "./interfaces/IKeyRegistry.sol";
import "./interfaces/IAccessRegistry.sol";
import "./protobufs/message.proto.sol";

pragma experimental ABIEncoderV2;



contract AccessRegistry is Ownable{    
    mapping(address=>address) _filters;
    mapping(address=>bytes32[]) _privateCastMembers;
    IKeyRegistry private _keyRegistry;
    IEddsaValidationModule private _eddsaValidationModule;
    IEd25519Lib private _ed25519Lib;

    constructor(address _keyRegistryAddress, address _eddsaValidationModuleAddress, address _ed25519LibAddress) {
        _setupOwner(msg.sender);
        _keyRegistry = IKeyRegistry(_keyRegistryAddress);
        _eddsaValidationModule = IEddsaValidationModule(_eddsaValidationModuleAddress);
        _ed25519Lib = IEd25519Lib(_ed25519LibAddress);
    }

     /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    function addFilter(
        IAccessRegistry.AddFilter calldata f
    ) external {
    
    (MessageData memory message_data, bytes memory hash) = _verifyMessage(
      f.message
    );

    IKeyRegistry.KeyData memory kd =  _keyRegistry.keyDataOf(message_data.fid, abi.encodePacked(f.pubkey));    
    require(kd.state==IKeyRegistry.KeyState.ADDED,"key unassigned");
    address vaddress = _ed25519Lib.getVirtualAddress(f.pubkey);
    address vaddressOfSender = _eddsaValidationModule.getEddsaVirtualAddress(msg.sender);
    require(vaddress == vaddressOfSender, "invalid smart account");
    address castAddress;
    assembly {
      castAddress := mload(add(hash,20))
    } 
    _filters[castAddress] = f.filter;
  }


    function _verifyMessage(
        bytes calldata message
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

    function joinPrivateCast(address casthash,bytes32 pubkey) external {
        //msg.sender must own the vaddress
        address vaddressContext = _eddsaValidationModule.getEddsaVirtualAddress(msg.sender);
        address vaddress = _ed25519Lib.getVirtualAddress(pubkey);
        require(vaddressContext == vaddress, "user not authorized to join private cast");
        address filter = _filters[casthash];
        if(filter !=address(0)){
            (bool success, bytes memory returnBytes) = filter.staticcall(abi.encodeWithSignature("executeFilter(address smartAccountAddress)",vaddress));
            require(success == true, "Call to access(address vaddress) failed");
            bool canAccess = abi.decode(returnBytes, (bool));
            require(canAccess == true , "user cannot join cast");
        }
        _privateCastMembers[casthash].push(pubkey);
  }

  function removePrivatCast(address casthash, bytes32 pubkey)   external{
      //TODO: get filter
      // execute filter with pubkey vaddress
      //if false, delete from _privateCastMemebers[casthash][pubkey]
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

interface IEddsaValidationModule{
 function getEddsaVirtualAddress(
        address smartAccount
    ) external view returns (address);
}

interface IEd25519Lib{
    function getVirtualAddress(bytes32 publicKey) external pure returns (address addr);
}