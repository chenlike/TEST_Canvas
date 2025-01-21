import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.28",


  networks:{

    test: {
      url: process.env.DEV_RPC_URL || "", 
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], 
    },


  }

};

export default config;
