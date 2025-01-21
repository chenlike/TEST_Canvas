import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";



function encodeColor(hexColor: string): number{
    if(hexColor.startsWith("#")){
        hexColor = hexColor.slice(1);
    }
    const uint24 = parseInt(hexColor, 16);
    return uint24;
}
function decodeColor(uint24: number | string): string{
    if(typeof uint24 === "string"){
        uint24 = parseInt(uint24, 10);
    }
    return "#" + uint24.toString(16).padStart(6, "0");
}

function encodeCoord(x: number, y: number): number {
    return (x << 16) | y;
}

function decodeCoord(encoded: number): { x: number; y: number } {
    const x = encoded >> 16;
    const y = encoded & 0xFFFF;
    return { x, y };
}

function randomRange(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

describe("Test", function () {

    // 加载合约
    async function deployCanvasLockFixture() {

        const Canvas = await hre.ethers.getContractFactory("Canvas");

        const canvas = await Canvas.deploy();

        return {Canvas,  canvas };
    }



    describe("Deployment", function () {
        it("Deployment ", async function () {
            await loadFixture(deployCanvasLockFixture);
        });

        it("Set Pixel", async function () {
            const { canvas } = await loadFixture(deployCanvasLockFixture);
            const [owner] = await hre.ethers.getSigners();


            await canvas.setPixel(0, 0, encodeColor("#ff0000"));

            let [ addr,expiry,color ] = await canvas.getPixel(0, 0)

            let deColor = decodeColor(color.toString());

            expect(deColor).to.equal("#ff0000");
            expect(addr).to.equal(owner.address);

        });

        it('Try Cover will fail ', async function(){
            const { canvas } = await loadFixture(deployCanvasLockFixture);
            const [owner,addr1] = await hre.ethers.getSigners();

            await canvas.setPixel(0, 0, encodeColor("#ff0000"));

            // will fail
            // chai 捕获异常
            await expect(canvas.connect(addr1).setPixel(0, 0, encodeColor("#00ff00"))).to.be.revertedWith("Pixel is locked now");


            await canvas.setPixel(0, 0, encodeColor("#ffff00"));

        })


        it("Set Pixel with expiry", async function () {
            const { canvas } = await loadFixture(deployCanvasLockFixture);
            const [owner,addr1] = await hre.ethers.getSigners();

            await canvas.setPixel(0, 0, encodeColor("#ff0000"));

            // 调整区块链时间
            await time.increase(11 * 60);

            await canvas.connect(addr1).setPixel(0, 0, encodeColor("#00ff00"))

            let [ addr,expiry,color ] = await canvas.getPixel(0, 0)
            expect(decodeColor(color.toString())).to.equal("#00ff00");

        });


        it("Batch set Pixel ", async function () {
            const { canvas } = await loadFixture(deployCanvasLockFixture);
        
            const [owner] = await hre.ethers.getSigners();
        
            const colors = [
                { x: 0, y: 0, color: "#ff0000" },
                { x: 1, y: 1, color: "#00ff00" },
                { x: 2, y: 2, color: "#0000ff" }
            ];
    
            // 批量设置像素
            const tx = await canvas.setPixels(
                colors.map(v => v.x),
                colors.map(v => v.y),
                colors.map(v => encodeColor(v.color))
            );

            // // 等待交易完成，获取交易回执
            // const receipt = await tx.wait();
            // // 获取实际用掉的 gas
            // const gasUsed = receipt!.gasUsed;
            // console.log("Gas used:", gasUsed.toString());
            // // 获取 gasPrice 并计算总费用
            // const gasPrice = tx.gasPrice;
            // const totalCost = gasUsed * gasPrice; // 使用 BigNumber 的乘法
            // console.log("Total cost in Wei:", totalCost.toString());
            // // wei转化为eth
            // console.log("Total cost in ETH:", hre.ethers.formatEther(totalCost));


            
            // 校验 setPixel
            for (let i = 0; i < colors.length; i++) {
                const [addr, expiry, color] = await canvas.getPixel(colors[i].x, colors[i].y);
                const deColor = decodeColor(color.toString());
                expect(deColor).to.equal(colors[i].color);
                expect(addr).to.equal(owner.address);
            }
        });
        

    });




});
