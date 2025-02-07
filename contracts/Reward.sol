// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IReward {

    function calcReward(
        uint256 totalAmount, // 总数量
        uint256 leftAmount,  // 剩余数量
        uint64 completedCount, // 已经完成的数量
        uint64 maxCompleteCount, // 最大完成数量限制
        bytes calldata data // 其他数据
    ) external returns (uint256);

}

// 均分奖励合约
contract AverageReward is IReward {

    function calcReward(
        uint256 totalAmount, // 总数量
        uint256 leftAmount,  // 剩余数量
        uint64 completedCount, // 已经完成的数量
        uint64 maxCompleteCount, // 最大完成数量限制
        bytes calldata data // 其他数据
    ) external pure returns (uint256) {

        // 边界检查，确保 maxCompleteCount 不为零
        require(maxCompleteCount > 0, "maxCompleteCount must be greater than zero");

        if(completedCount > maxCompleteCount) {
            return 0;
        }

        // 计算每个任务的奖励
        uint256 reward = totalAmount / maxCompleteCount;

        // 如果剩余的奖励小于每个任务的奖励，则返回剩余奖励
        if(leftAmount < reward) {
            return leftAmount;
        }

        return reward;
    }
}

// 固定奖励合约 从data中获取每一名的奖励数量
contract FixedReward is IReward {

    function calcReward(
        uint256 totalAmount,  // 总数量
        uint256 leftAmount,   // 剩余数量
        uint64 completedCount, // 已经完成的数量
        uint64 maxCompleteCount, // 最大完成数量限制
        bytes calldata data   // 其他数据
    ) external pure returns (uint256) {

        // 如果已经完成的任务数超过最大限制，返回0奖励
        if (completedCount > maxCompleteCount) {
            return 0;
        }


        
        (uint256[] memory rewards) = abi.decode(data, (uint256[]));



        // 判断数组是否越界
        require(completedCount < rewards.length, "completedCount is out of range");

        // 判断剩余是否足够
        require(rewards[completedCount] <= leftAmount, "condition is not met");


        // 返回奖励
        return rewards[completedCount];
    }

}
