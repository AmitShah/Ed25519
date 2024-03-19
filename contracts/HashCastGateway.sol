// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@thirdweb-dev/contracts/external-deps/openzeppelin/utils/cryptography/EIP712.sol";
pragma experimental ABIEncoderV2;

import "./libraries/Ed25519.sol";
import "hardhat/console.sol";

contract HashCastGateway is EIP712{
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;

  
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    //the linear emission rate of rewards over time
    uint256 public rewardPerBlock;
    mapping(bytes32=>uint256) edPubKeyBlockClaimBlock;
    mapping(string=>uint256) edPubKeyCastTransfer;
    mapping(bytes32=>uint256) edPubKeyNonce;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    constructor()  EIP712("HashCastGateway", "1.0.0"){
        // address _stakingToken;
        // address _rewardToken;
        owner = msg.sender;
        // stakingToken = IERC20(_stakingToken);
        // rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }


    function verifyEddsa(   bytes32 k,
        bytes32 r,
        bytes32 s,
        bytes memory m) internal pure returns (bool){
         return Ed25519.verify(k, r, s, m);
    }

    //TODO: this should be only owner to prevent sybil of claiming many addresses and upvoting
    // A better solution is if this is deployed on Optimism and check the key registry contract to make sure 
    // the address has registered with the app_fid !
    function claim(bytes32 k, bytes32 r, bytes32 s) public {
        uint256 nonce = edPubKeyNonce[k];
        console.logBytes32(_domainSeparatorV4());
        console.logBytes32(k);
        console.log(block.chainid);
        bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
            //TODO: need replay protection on the struct
          keccak256("Claim(bytes32 address,uint256 nonce)"),
          k,nonce))));
        console.log("digest:");
        console.logBytes(digest);
        bool valid = verifyEddsa(k, r, s, digest);
        require(valid,"invalid signature");
        console.log("VALID SIGNAUTE");
        uint256 lastClaimBlock = edPubKeyBlockClaimBlock[k];
        uint256 blockNumber = block.number;
        require(blockNumber > lastClaimBlock, "invalid block number");
        uint256 amount=0;
        if(lastClaimBlock > 0){
            amount=10;
        }else{           
            amount = (blockNumber - lastClaimBlock) * rewardPerBlock;                        
        }
        //TODO:mint karma
        edPubKeyBlockClaimBlock[k] = blockNumber; 
    }

    //transfer to user or anything really
    //to is a blake3 160 bit hash, so we can store it in an address field
    function transferToCast(bytes32 k, string calldata to, uint256 amount, bytes32 r, bytes32  s) public {
        bytes memory digest = abi.encodePacked(_hashTypedDataV4(keccak256(abi.encode(
          keccak256("Transfer(uint256 amount,bytes32 from,string to)"),
          amount,k,keccak256(abi.encodePacked(to))))));
        console.log("digest:");
        console.logBytes(digest);
        bool valid = verifyEddsa(k, r, s, digest);
        require(valid,"invalid signature");

        require(edPubKeyCastTransfer[to]==0,"already transferred to cast");

        //TODO: transfer 

        edPubKeyCastTransfer[to]=amount;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored
            + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18)
                / totalSupply;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint256) {
        return (
            (
                balanceOf[_account]
                    * (rewardPerToken() - userRewardPerTokenPaid[_account])
            ) / 1e18
        ) + rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint256 _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
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
}
