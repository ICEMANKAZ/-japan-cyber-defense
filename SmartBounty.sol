// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SmartBountySystem {
    
    address public owner; // セキュリティオーナー（あなた）
    uint256 public constant OWNER_FEE_PERCENT = 5;      // あなたの利益（5%）
    uint256 public constant HACKER_REWARD_PERCENT = 20; // 海外ハッカーへの報酬（20%）
    uint256 public constant VICTIM_REFUND_PERCENT = 75; // 高齢者への返金（75%）

    struct BountyQuest {
        address payable victimAddress; // 高齢者の返金先
        uint256 targetAmount;          // 奪われた目標金額
        bool isCleared;                // クエストが解決したか
    }

    // 詐欺師のサイフアドレス => クエスト情報
    mapping(address => BountyQuest) public bountyBoard;
    // 詐欺師ブラックリスト
    mapping(address => bool) public activeBounties;

    // イベントログ（海外ハッカー向けのクエスト掲示板）
    event BountyPosted(address indexed scammer, uint256 targetAmount);
    event BountyCleared(address indexed scammer, address indexed hacker, uint256 totalRecovered);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call.");
        _;
    }

    constructor() {
        owner = 0x0Fd8C768EA8d40AA94d633C3103685724852Fd78; 
    }

    function postBounty(address _scammer, address payable _victim, uint256 _amount) external onlyOwner {
        require(_scammer != address(0) && _victim != address(0), "Invalid address");
        require(!activeBounties[_scammer], "Bounty already active.");

        bountyBoard[_scammer] = BountyQuest({
            victimAddress: _victim,
            targetAmount: _amount,
            isCleared: false
        });
        activeBounties[_scammer] = true;

        emit BountyPosted(_scammer, _amount);
    }

    function claimBounty(address _scammer) external payable {
        require(activeBounties[_scammer], "No active bounty for this scammer.");
        BountyQuest storage quest = bountyBoard[_scammer];
        require(!quest.isCleared, "Bounty already claimed.");

        uint256 totalRecovered = msg.value;
        require(totalRecovered > 0, "No funds recovered.");

        address hacker = msg.sender;

        uint256 ownerFee = (totalRecovered * OWNER_FEE_PERCENT) / 100;
        uint256 hackerReward = (totalRecovered * HACKER_REWARD_PERCENT) / 100;
        uint256 victimRefund = totalRecovered - ownerFee - hackerReward;

        payable(owner).transfer(ownerFee);
        payable(hacker).transfer(hackerReward);
        quest.victimAddress.transfer(victimRefund);

        quest.isCleared = true;
        activeBounties[_scammer] = false;

        emit BountyCleared(_scammer, hacker, totalRecovered);
    }
}
