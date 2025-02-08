pragma circom 2.0.0;

import "hashes/sha256/sha256.circom";  // 导入 SHA256 库
import "circomlib/ethsig.circom";      // 导入验证签名的 Circom 库

template SHA256Verification() {
    signal input answer;  // 用户输入的字符串答案
    signal input hashedAnswer;  // 经过 SHA256 加密后的答案哈希值
    signal input userAddress;  // 用户的地址
    signal input userSignature;  // 用户的签名
    signal[8] hashOutput;  // SHA256 输出的 8 个 256-bit 字

    // 使用 SHA256 电路计算输入 answer 的哈希值
    component sha256 = SHA256(256);
    sha256.in[0] <== answer;  // 将用户的字符串答案作为输入
    hashOutput <== sha256.out;  // 获取答案的 SHA256 哈希值

    // 使用签名验证电路验证用户签名
    component sigVerify = ETHSig();
    sigVerify.message <== hashedAnswer;  // 用户提供的答案哈希
    sigVerify.signature <== userSignature;  // 用户提供的签名
    sigVerify.address <== userAddress;  // 用户地址
    
    // 验证签名是否有效
    sigVerify.checkSignature();

    // 比较用户提供的哈希值和计算出的哈希值
    for (var i = 0; i < 8; i++) {
        hashOutput[i] === hashedAnswer[i];  // 比较哈希值是否一致
    }
}

component main = SHA256Verification();
