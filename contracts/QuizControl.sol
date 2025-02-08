// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./RuleChecker.sol";
import "./Reward.sol";

enum QuizStatus {
    NotStarted,
    InProgress,
    Ended
}



contract QuizControl {
    

    mapping(uint64 => Quiz) public quizzes;

    struct Quiz {
        // id
        uint64 id;
        // 控制人
        address owner;
        // 状态
        QuizStatus status;
        // 过期时间
        uint32 expiry;


        // 奖励代币地址
        address rewardToken;

        // 总共奖励的数量
        uint256 totalReward;

        // 已经领取的奖励数量
        uint256 claimedReward;

        // 可以奖励的最大人数
        uint32 maxRewardCount;

        // 答题详细信息ipfs
        string info;

        // 规则检查器
        address checker;

        // 奖励计算器
        address rewarder;

        // 已经完成的人数
        uint32 finishedCount;

        // 加密的答案
        bytes32 encryptedAnswer; 

    }

    struct QuizReward {
        // 领取的数量
        uint256 totalReward;
        // 已经领取的数量
        uint256 claimedReward;

        // 排名
        uint256 rank;

    }



    mapping(uint64 => mapping(address=>QuizReward)) public rewards;



    uint64 _totalQuizzes;


    function getTotalQuizzes() public view returns (uint64) {
        return _totalQuizzes;
    }

    // 创建事件
    event QuizCreated(uint64 indexed quizId, address indexed owner, uint256 totalReward, uint32 maxRewardCount, string info);
    // 状态变更事件
    event QuizStatusChanged(uint64 indexed quizId, QuizStatus status);
    // 管理人在结束后可以调用这个方法，直接取回剩余的奖励
    event QuizWithdrawReward(uint64 indexed quizId, address indexed owner, uint256 withdrawReward);
 
    function createQuiz(
        uint32 expiry,
        address rewardToken,
        uint256 totalReward,
        uint32 maxRewardCount,
        string memory info,
        address checker,
        address rewarder,
        address owner,
        bool startNow,
        bytes32 encryptedAnswer
    ) public returns (uint64) {
        _totalQuizzes++;

        // 过期时间必须要大于当前时间
        require(expiry > block.timestamp, "expiry must be greater than current time");

        // 奖励代币地址不能为空
        require(rewardToken != address(0), "rewardToken is zero address");


        address _owner = msg.sender;
        if(owner != address(0)) {
            _owner = owner;
        }

        if(totalReward > 0) {
            // 奖励代币必须要有足够的数量
            IERC20 token = IERC20(rewardToken);
            require(token.balanceOf(msg.sender) >= totalReward, "not enough reward token");
            // 转移代币到合约中
            bool transfer = token.transferFrom(owner, address(this), totalReward);
            require(transfer, "transfer reward token failed");
        }


        Quiz memory quiz = Quiz({
            id: _totalQuizzes,
            owner: _owner,
            status: QuizStatus.NotStarted,
            expiry: expiry,
            rewardToken: rewardToken,
            totalReward: totalReward,
            claimedReward: 0,
            maxRewardCount: maxRewardCount,
            info: info,
            checker: checker,
            rewarder: rewarder,
            finishedCount: 0,
            encryptedAnswer: encryptedAnswer
        });


        if(startNow) {
            quiz.status = QuizStatus.InProgress;
            emit QuizStatusChanged(quiz.id, QuizStatus.InProgress);
        }



        quizzes[_totalQuizzes] = quiz;
        emit QuizCreated(quiz.id, _owner, totalReward, maxRewardCount, info);

        return _totalQuizzes;
    }   

    // 开启答题
    function startQuiz(uint64 quizId) public {
        Quiz storage quiz = quizzes[quizId];
        require(quiz.owner == msg.sender, "only owner can start quiz");
        require(quiz.status == QuizStatus.NotStarted, "quiz status is not NotStarted");
        require(quiz.expiry > block.timestamp, "quiz is expired");

        quiz.status = QuizStatus.InProgress;
        emit QuizStatusChanged(quiz.id, quiz.status );
    }

    // 结束答题
    function endQuiz(uint64 quizId) public {
        Quiz storage quiz = quizzes[quizId];
        require(quiz.owner == msg.sender, "only owner can end quiz");
        require(quiz.status == QuizStatus.InProgress, "quiz status is not InProgress");

        quiz.status = QuizStatus.Ended;
        emit QuizStatusChanged(quiz.id, quiz.status );
    }

    // owner在结束后可以调用这个方法，直接取回剩余的奖励
    function withdrawReward(uint64 quizId) public {
        Quiz storage quiz = quizzes[quizId];
        require(quiz.owner == msg.sender, "only owner can withdraw reward");
        // 只有结束或已过期的才能取回
    
        require(quiz.status == QuizStatus.Ended || quiz.expiry < block.timestamp, "quiz status is not Ended");

        IERC20 token = IERC20(quiz.rewardToken);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= quiz.totalReward - quiz.claimedReward, "not enough reward token");

        (bool success, uint256 rewardAmount) = Math.trySub(quiz.totalReward, quiz.claimedReward);
        require(success, "sub get withdraw failed");

        bool transfer = token.transfer(quiz.owner,rewardAmount);
        require(transfer, "transfer reward token failed");
        emit QuizWithdrawReward(quiz.id, quiz.owner, rewardAmount);
    }


    function getQuiz(uint64 quizId) public view returns (Quiz memory) {
        return quizzes[quizId];
    }


    
    

    // 使用零知识证明来验证答案
    function submitAnswer(uint64 quizId, bytes calldata zkProof) public {
        Quiz storage quiz = quizzes[quizId];
        // 只有在进行中的才能提交答案
        require(quiz.status == QuizStatus.InProgress, "quiz is not in progress");
        // 只有在过期时间之前才能提交答案
        require(quiz.expiry > block.timestamp, "quiz is expired");
        // finishedCount 必须小于 maxRewardCount
        require(quiz.finishedCount < quiz.maxRewardCount, "quiz is finished");

        // 这里验证零知识证明
        // 假设 zkProof 是由用户提供的零知识证明，使用某个零知识证明库验证证明
        bool validProof = ZKVerifier.verify(zkProof, quiz.encryptedAnswer); // 根据你选择的ZK库来实现

        require(validProof, "invalid proof");

        // 处理用户提交的答案，例如奖励发放
        // 记录用户的完成情况、奖励发放等
        quiz.finishedCount++;
    }











}
