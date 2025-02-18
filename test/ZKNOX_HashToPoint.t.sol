// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/HashToPoint_ZKNOX.sol";

contract HashToPointZKNOXTest is Test {
    function test_simon() public pure {
        bytes memory salt = "123";
        bytes memory msgHash = "456";
        uint256 q = 12289;
        uint256 n = 512;
        uint256[] memory hash = hashToPoint(salt, msgHash, q, n);
        console.log(hash[0]);
        // assertEq(computed_output_4_3, output_4_3);
    }
}
