// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./RuleChecker.sol";

enum QuizStatus {
    NotStarted,
    InProgress,
    Completed
}



contract QuizControl {
    struct Quiz {
        uint64 id;
        address owner;
        QuizStatus status;
        uint32 expiry;
        // 奖励代币地址
        address rewardToken;
        // 总共奖励的数量
        uint256 totalReward;
        // 已经领取的奖励数量
        uint256 claimedReward;
        // 答题人数
        uint32 rewardCount;

        // 答题详细信息ipfs
        string info;


        IRuleChecker checker;



    }

    uint64 _totalQuizzes;

    mapping(uint64 => Quiz) public quizzes;






}
