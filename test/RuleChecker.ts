import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre, { ethers } from "hardhat";



describe("Checker", function () {

    // 加载合约
    async function deployERC20CheckerLockFixture() {

        const RuleChecker = await hre.ethers.getContractFactory("ERC20RuleChecker");

        const checker = await RuleChecker.deploy();

        return { RuleChecker, checker };
    }

    async function deployTestToken() {
        const TestToken = await hre.ethers.getContractFactory("TestToken");

        const testToken = await TestToken.deploy(100);

        return { TestToken, testToken };
    }



    const abiCoder = new ethers.AbiCoder();

    describe("ERC20RuleChecker", function () {
        it("Test Token at least 10 ", async function () {

            const { checker } = await loadFixture(deployERC20CheckerLockFixture);
            const { testToken } = await loadFixture(deployTestToken)

            const [owner, addr1] = await hre.ethers.getSigners();

            let data = abiCoder.encode(["address", "uint256"], [await testToken.getAddress(), 10])

            let res = await checker.validate(owner.address, data);

            expect(res).to.equal(true);

        });

        it("Test Token at least 10 Fail Type ", async function () {

            const { checker } = await loadFixture(deployERC20CheckerLockFixture);
            const { testToken } = await loadFixture(deployTestToken)

            const [owner, addr1] = await hre.ethers.getSigners();

            let data = abiCoder.encode(["address", "uint256"], [await testToken.getAddress(), 10])

            let res = await checker.validate(addr1.address, data);

            expect(res).to.equal(false);

        });





    });




});


describe("Reward", function () {

    // 部署 AverageReward 合约
    async function deployAverageReward() {
        const AverageReward = await hre.ethers.getContractFactory("AverageReward");
        const averageReward = await AverageReward.deploy();
        return { AverageReward, averageReward };
    }

    // 部署 FixedReward 合约
    async function deployFixedReward() {
        const FixedReward = await hre.ethers.getContractFactory("FixedReward");
        const fixedReward = await FixedReward.deploy();
        return { FixedReward, fixedReward };
    }

    const abiCoder = new ethers.AbiCoder();

    describe("AverageReward", function () {
        it("should calculate reward correctly for at least 10 completed tasks", async function () {
            const { averageReward } = await loadFixture(deployAverageReward);

            const [owner] = await hre.ethers.getSigners();

            const totalAmount = ethers.parseUnits("1000", 18);  // 1000 tokens
            const leftAmount = ethers.parseUnits("500", 18);    // 500 tokens remaining
            const completedCount = 5;  // Already completed 5 tasks
            const maxCompleteCount = 10;  // Total 10 tasks


            let reward = await averageReward.calcReward(totalAmount, leftAmount, completedCount, maxCompleteCount, "0x");

            // Expected reward should be totalAmount / maxCompleteCount = 1000 / 10 = 100
            expect(reward).to.equal(ethers.parseUnits("100", 18));
        });

        it("should return remaining tokens if the reward exceeds the left amount", async function () {
            const { averageReward } = await loadFixture(deployAverageReward);

            const [owner] = await hre.ethers.getSigners();

            const totalAmount = ethers.parseUnits("1000", 18);  // 1000 tokens
            const leftAmount = ethers.parseUnits("50", 18);     // Only 50 tokens left
            const completedCount = 5;  // Already completed 5 tasks
            const maxCompleteCount = 10;  // Total 10 tasks

            let reward = await averageReward.calcReward(totalAmount, leftAmount, completedCount, maxCompleteCount, "0x");

            // Expected reward is 50 because it's less than the calculated reward
            expect(reward).to.equal(leftAmount);
        });
    });

    describe("FixedReward", function () {
        it("should calculate fixed rewards correctly", async function () {
            const { fixedReward } = await loadFixture(deployFixedReward);

            const [owner] = await hre.ethers.getSigners();


            const rewards = [
                ethers.parseUnits("1000", 18),  // 1st place
                ethers.parseUnits("500", 18),   // 2nd place
                ethers.parseUnits("200", 18),   // 3rd place
                ethers.parseUnits("50", 18),    // 4th place
                ethers.parseUnits("50", 18),    // 5th place
                ethers.parseUnits("50", 18),    // 6th place
                ethers.parseUnits("50", 18),    // 7th place
                ethers.parseUnits("50", 18),    // 8th place
                ethers.parseUnits("50", 18),    // 9th place
                ethers.parseUnits("50", 18)     // 10th place
            ];

            const totalAmount = ethers.parseUnits("2050", 18);  // 1000 tokens
            const leftAmount = ethers.parseUnits("2050", 18);    // 500 tokens remaining
            let completedCount = 0;  // Already completed 3 tasks
            const maxCompleteCount = 10;  // Total 10 tasks



            let data = abiCoder.encode(["uint256[]"], [rewards]);

            let reward = await fixedReward.calcReward(totalAmount, leftAmount, completedCount, maxCompleteCount, data);

            // Expected reward should be the sum of the rewards for the first 3 tasks: 1000 + 500 + 200 = 1700
            // But we only have 500 tokens left, so return 500 tokens
            expect(reward).to.equal(ethers.parseUnits("1000", 18));  // 500 tokens

            completedCount = 2;  
            reward = await fixedReward.calcReward(totalAmount, leftAmount, completedCount, maxCompleteCount, data);
            expect(reward).to.equal(ethers.parseUnits("200", 18));  



            completedCount = 3;  
            reward = await fixedReward.calcReward(totalAmount, leftAmount, completedCount, maxCompleteCount, data);
            expect(reward).to.equal(ethers.parseUnits("50", 18));  

        });

    });
});