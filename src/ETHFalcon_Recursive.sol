// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {NTT} from "./NTT_Recursive.sol";
import {NTT_iterative} from "./NTT_Iterative.sol";
import {Test, console} from "forge-std/Test.sol";
// TODO: make it a library (aka unfuck constants/data)
import "./HashToPoint_tetration.sol"; //not recommended, here for benchmarks against tetration only

contract ETHFalcon {
    uint256 constant n = 512;
    uint256 constant sigBound = 34034726;
    uint256 constant sigBytesLen = 666;
    uint256 constant q = 12289;
    NTT ntt;
    NTT_iterative ntt_iterative;

    struct Signature {
        bytes salt;
        int256[] s1;
    }

    struct FalconRecover_sig {
        bytes r;
        uint256[] s1;
        uint256[] s2;
        uint256[] ntts2m1;
    }

    constructor() {
        ntt = new NTT();
        ntt_iterative = new NTT_iterative();
    }

    function verify(
        bytes memory msgs,
        Signature memory signature,
        uint256[] memory h // public key
    ) public view returns (address) {
        require(h.length == 512, "Invalid public key length");
        require(signature.s1.length == 512, "Invalid signature length");
        uint256[] memory s1 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s1[i] = uint256(int256(q) + signature.s1[i]);
            } else {
                s1[i] = uint256(signature.s1[i]);
            }
        }
        uint256[] memory hashed = hashToPoint(signature.salt, msgs, q, n);
        uint256[] memory s0 = ntt.subZQ(hashed, ntt.mulZQ(s1, h));
        uint256 qs1 = 6144; // q >> 1;
        // normalize s0 // to positive cuz you'll **2 anyway?
        for (uint256 i = 0; i < n; i++) {
            if (s0[i] > qs1) {
                s0[i] = q - s0[i];
            } else {
                s0[i] = s0[i];
            }
        }

        // normalize s1
        for (uint256 i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }

        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s0[i] * s0[i];
            norm += s1[i] * s1[i];
        }
        require(norm < sigBound, "Signature is invalid");
    }

    //a version optimized by precomputing the NTT for of the public key
    function verify_nttpub(
        bytes memory msgs,
        Signature memory signature,
        uint256[] memory ntt_h // public key, ntt form
    ) public view returns (address) {
        require(ntt_h.length == 512, "Invalid public key length");
        require(signature.s1.length == 512, "Invalid signature length");
        uint256[] memory s1 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s1[i] = uint256(int256(q) + signature.s1[i]);
            } else {
                s1[i] = uint256(signature.s1[i]);
            }
        }
        uint256[] memory hashed = hashToPoint(signature.salt, msgs, q, n);
        uint256[] memory s0 = ntt.subZQ(hashed, ntt.mulZQ_opt(s1, ntt_h));
        uint256 qs1 = 6144; // q >> 1;
        // normalize s0 // to positive cuz you'll **2 anyway?
        for (uint256 i = 0; i < n; i++) {
            if (s0[i] > qs1) {
                s0[i] = q - s0[i];
            } else {
                s0[i] = s0[i];
            }
        }
        // normalize s1
        for (uint256 i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }
        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s0[i] * s0[i];
            norm += s1[i] * s1[i];
        }
        require(norm < sigBound, "Signature is invalid");
    }

    //a version optimized by precomputing the NTT for of the public key
    function verify_nttpub_iterative(
        bytes memory msgs,
        Signature memory signature,
        uint256[] memory ntt_h // public key, ntt form
    ) public view returns (address) {
        require(ntt_h.length == 512, "Invalid public key length");
        require(signature.s1.length == 512, "Invalid signature length");
        uint256[] memory s1 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s1[i] = uint256(int256(q) + signature.s1[i]);
            } else {
                s1[i] = uint256(signature.s1[i]);
            }
        }
        uint256[] memory hashed = hashToPoint(signature.salt, msgs, q, n);
        uint256[] memory s0 = ntt_iterative.subZQ(hashed, ntt_iterative.mul_halfNTTPoly(s1, ntt_h));
        uint256 qs1 = 6144; // q >> 1;
        // normalize s0 // to positive cuz you'll **2 anyway?
        for (uint256 i = 0; i < n; i++) {
            if (s0[i] > qs1) {
                s0[i] = q - s0[i];
            } else {
                s0[i] = s0[i];
            }
        }
        // normalize s1
        for (uint256 i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }
        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s0[i] * s0[i];
            norm += s1[i] * s1[i];
        }
        require(norm < sigBound, "Signature is invalid");
    }

    //returns the hash of the public key from a signature, see readme for optimizations from front
    function recover(FalconRecover_sig memory signature) public view returns (address) {
        uint256[] memory s1 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s1[i] = uint256(int256(q) + int256(signature.s1[i]));
            } else {
                s1[i] = uint256(signature.s1[i]);
            }
        }
        uint256[] memory s2 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s2[i] = uint256(int256(q) + int256(signature.s2[i]));
            } else {
                s2[i] = uint256(signature.s2[i]);
            }
        }

        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s2[i] * s2[i];
            norm += s1[i] * s1[i];
        }
        require(norm < sigBound, "Signature is invalid");

        uint256[] memory ntt_s2m1 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            ntt_s2m1[i] = signature.ntts2m1[i];
        }
        ntt_s2m1 = ntt_iterative.modmulx512(s2, ntt_s2m1);

        //test hashed==ntt(1)
        s2 = ntt_iterative.subZQ(ntt_s2m1, s1);
        return address(uint160(uint256(keccak256(abi.encodePacked(s2)))));
    }
}
