// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Keccak256PRNG} from "../src/ZKNOX_keccak_prng.sol";

contract KeccakPRNGTest is Test {
    // ans generated from python code
    bytes input = "test input"; // in hex: "7465737420696e707574"
    bytes output = hex"5b9e99370fa4b753ac6bf0d246b3cec353c84a67839f5632cb2679b4ae565601";
    Keccak256PRNG keccak_prng;

    function setUp() public {
        keccak_prng = new Keccak256PRNG();
    }

    function test_keccak_prng() public {
        keccak_prng.inject(input);
        keccak_prng.flip();
        assertEq(output, keccak_prng.extract(32));
    }
}
