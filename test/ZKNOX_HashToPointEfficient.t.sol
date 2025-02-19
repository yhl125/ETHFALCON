// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZKNOX_HashToPointEfficient} from "../src/HashToPointEfficient_ZKNOX.sol";

contract HashToPointZKNOXTest is Test {
    function test_H2P_Zhenfei() public {
        ZKNOX_HashToPointEfficient H2P = new ZKNOX_HashToPointEfficient();

        bytes memory salt =
            "5\x001\x8fu\xad \xf0\xaa b\xba\x1c4\x8a\xfe\xaaI#\x87\xa4c\xeb\x8c(\xafw\x9dj>\xa6\x96\xeb\xb9f\x0c\xcf\xf5\x06-";
        bytes memory msgHash = "My name is Renaud";
        uint256 q = 12289;
        uint256 n = 512;
        uint256[] memory hash = H2P.hashToPoint(salt, msgHash, q, n);
        // obtained from python
        assertEq(hash[0], 2918);
        assertEq(hash[1], 6850);
        assertEq(hash[2], 8308);
        assertEq(hash[3], 8464);
        assertEq(hash[4], 5824);
    }

}
