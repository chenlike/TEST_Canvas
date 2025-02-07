// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRuleChecker {
    function validate(
        address user,
        bytes calldata data
    ) external returns (bool);



    
}

contract ERC20RuleChecker is IRuleChecker {



    function validate(
        address user,
        bytes calldata data
    ) external view returns (bool) {

        (address token, uint256 minAmount) = abi.decode(data, (address, uint256));

        IERC20 erc20 = IERC20(token);
        return erc20.balanceOf(user) >= minAmount;
    }


}



