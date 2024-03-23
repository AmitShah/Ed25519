// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/cryptography/EIP712.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "./libraries/Ed25519.sol";
import "hardhat/console.sol";
import "./interfaces/IHashCastKarma.sol";
import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/Counters.sol";

pragma experimental ABIEncoderV2;

contract HashCastGateway is EIP712, Ownable{
    using Counters for Counters.Counter;
    IERC20 public immutable karmaToken;

    //the linear emission rate of rewards over time
    uint256 public rewardPerBlock;
    mapping(address=>uint256) edPubKeyBlockClaimBlock;
    mapping(address=>uint256) edPubKeyCastTransfer;
    mapping(address => Counters.Counter) private _nonces;

    constructor(address _karmaToken)  EIP712("HashCastGateway", "1.0.0") {
        _setupOwner(msg.sender);
        karmaToken = IERC20(_karmaToken);
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

    //TODO: this should be only owner to prevent sybil of claiming many addresses and upvoting
    // A better solution is if this is deployed on Optimism and check the key registry contract to make sure 
    // the address has registered with the app_fid !
    function claim(IHashCastKarma.ClaimRequest calldata c) public {
        address vaddress = Ed25519.getVirtualAddress(c.pubkey);
        uint256 nonce = _useNonce(vaddress);       
        
        // console.logBytes32(_domainSeparatorV4());
        // console.logBytes32(k);
        // console.log(block.chainid);
        bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
            //TODO: need replay protection on the struct
          keccak256("Claim(address from,uint256 nonce)"),
          vaddress,nonce))));
        // console.log("digest:");
        // console.logBytes(digest);
        bool valid = Ed25519.verify(c.pubkey, c.r, c.s, digest);
        require(valid,"invalid signature");
        // console.log("VALID SIGNAUTE");
        uint256 lastClaimBlock = edPubKeyBlockClaimBlock[vaddress];
        uint256 blockNumber = block.number;
        require(blockNumber > lastClaimBlock, "invalid block number");
        uint256 amount=0;
        if(lastClaimBlock == 0){
            amount=10;
        }else{           
            amount = (blockNumber - lastClaimBlock) * rewardPerBlock;                        
        }
        karmaToken.mintTo(vaddress,amount);
        edPubKeyBlockClaimBlock[vaddress] = blockNumber; 
    }


    //TODO: thi should be a multicall that 1. permits the karamtoken the transfers the exact amount in a single context
    //to is a blake3 160 bit hash, so we can store it in an address field
    function transferWithAuthorization(IHashCastKarma.TransferRequest calldata t) public {
        karmaToken.transferWithAuthorization(t.pubkey,t.to,t.value,t.deadline,t.r,t.s);
    }

    //TODO: allow user to input message bytes to pull the karma on the message
    // function pullKarma(){

    // }
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
