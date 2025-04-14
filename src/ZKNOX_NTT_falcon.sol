/**
 *
 */
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN        NNNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                         ..../&@&#.       .###%@@@#, ..                         
/*Z:::::::::::::::::ZK:::::::K    K:::::KN:::::::N       N::::::N   OO:::::::::OO   X:::::X       X:::::X                      ...(@@* .... .           &#//%@@&,.                       
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::::N      N::::::N OO:::::::::::::OO X:::::X       X:::::X                    ..*@@.........              .@#%%(%&@&..                    
/*Z:::ZZZZZZZZ:::::Z K:::::::K   K::::::KN:::::::::N     N::::::NO:::::::OOO:::::::OX::::::X     X::::::X                   .*@( ........ .  .&@@@@.      .@%%%%%#&@@.                  
/*ZZZZZ     Z:::::Z  KK::::::K  K:::::KKKN::::::::::N    N::::::NO::::::O   O::::::OXXX:::::X   X::::::XX                ...&@ ......... .  &.     .@      /@%%%%%%&@@#                  
/*        Z:::::Z      K:::::K K:::::K   N:::::::::::N   N::::::NO:::::O     O:::::O   X:::::X X:::::X                   ..@( .......... .  &.     ,&      /@%%%%&&&&@@@.              
/*       Z:::::Z       K::::::K:::::K    N:::::::N::::N  N::::::NO:::::O     O:::::O    X:::::X:::::X                   ..&% ...........     .@%(#@#      ,@%%%%&&&&&@@@%.               
/*      Z:::::Z        K:::::::::::K     N::::::N N::::N N::::::NO:::::O     O:::::O     X:::::::::X                   ..,@ ............                 *@%%%&%&&&&&&@@@.               
/*     Z:::::Z         K:::::::::::K     N::::::N  N::::N:::::::NO:::::O     O:::::O     X:::::::::X                  ..(@ .............             ,#@&&&&&&&&&&&&@@@@*               
/*    Z:::::Z          K::::::K:::::K    N::::::N   N:::::::::::NO:::::O     O:::::O    X:::::X:::::X                   .*@..............  . ..,(%&@@&&&&&&&&&&&&&&&&@@@@,               
/*   Z:::::Z           K:::::K K:::::K   N::::::N    N::::::::::NO:::::O     O:::::O   X:::::X X:::::X                 ...&#............. *@@&&&&&&&&&&&&&&&&&&&&@@&@@@@&                
/*ZZZ:::::Z     ZZZZZKK::::::K  K:::::KKKN::::::N     N:::::::::NO::::::O   O::::::OXXX:::::X   X::::::XX               ...@/.......... *@@@@. ,@@.  &@&&&&&&@@@@@@@@@@@.               
/*Z::::::ZZZZZZZZ:::ZK:::::::K   K::::::KN::::::N      N::::::::NO:::::::OOO:::::::OX::::::X     X::::::X               ....&#..........@@@, *@@&&&@% .@@@@@@@@@@@@@@@&                  
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N       N:::::::N OO:::::::::::::OO X:::::X       X:::::X                ....*@.,......,@@@...@@@@@@&..%@@@@@@@@@@@@@/                   
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N        N::::::N   OO:::::::::OO   X:::::X       X:::::X                   ...*@,,.....%@@@,.........%@@@@@@@@@@@@(                     
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN         NNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                      ...&@,....*@@@@@ ..,@@@@@@@@@@@@@&.                     
/*                                                                                                                                   ....,(&@@&..,,,/@&#*. .                             
/*                                                                                                                                    ......(&.,.,,/&@,.                                
/*                                                                                                                                      .....,%*.,*@%                               
/*                                                                                                                                    .#@@@&(&@*,,*@@%,..                               
/*                                                                                                                                    .##,,,**$.,,*@@@@@%.                               
/*                                                                                                                                     *(%%&&@(,,**@@@@@&                              
/*                                                                                                                                      . .  .#@((@@(*,**                                
/*                                                                                                                                             . (*. .                                   
/*                                                                                                                                              .*/
///* Copyright (C) 2025 - Renaud Dubois, Simon Masson - This file is part of ZKNOX project
///* License: This software is licensed under MIT License
///* This Code may be reused including this header, license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: ZKNOX_NTT.sol
///* Description: Compute Negative Wrap Convolution NTT as specified in EIP-NTT
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_falcon_utils.sol";

//// internal version to spare call data cost

// NTT_FW as specified by EIP, statefull version
//address apsirev: address of the contract storing the powers of psi
function _ZKNOX_NTTFW(uint256[] memory a, address apsirev) view returns (uint256[] memory) {
    uint256 t = n;
    uint256 m = 1;

    uint256[1] memory S;

    assembly ("memory-safe") {
        for {} gt(n, m) {} {
            //while(m<n)
            t := shr(1, t)
            for { let i := 0 } gt(m, i) { i := add(i, 1) } {
                let j1 := shl(1, mul(i, t))
                let j2 := sub(add(j1, t), 1) //j2=j1+t-1;

                extcodecopy(apsirev, S, mul(add(i, m), 2), 2) //psi_rev[m+i]
                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj)

                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mulmod(mload(a_aj), shr(240, mload(S)), q)
                    mstore(a_aj, addmod(U, sub(q, V), q))
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q))
                }
            }
            m := shl(1, m) //m=m<<1
        }
    }
    return a;
}

function _ZKNOX_NTTFW_vectorized(uint256[] memory a) pure returns (uint256[] memory) {
    uint256[32] memory psirev = [
        uint256(0x16e40c7b04bc29930e25261022510dd61fdb166802d22ae80fcb1be72a3a0001), 
        0x5471c8f1970230116c4139f1e1216602549244324622dce2c4c25c00a4f1d2c, 
        0x270b2bdb222012c50e8023c2254612ee2ad313de0bc623802ceb2c462b6f090f, 
        0x2d2b1dfe28c42f752531299e1f622b68093e24161ce1246e2c191f212fb00c13, 
        0x27d81c1d0cd40b410ca902d9232807dd06a00594014e097a19861218112404ec, 
        0x18ea1ce720a525561a5b00910d830e351f7a260d2e9e0d36218629221bc62193, 
        0x2624056522011fb01c841b2e10b629780220169f0153265d000903fe01e024e7, 
        0x1b030b1500821eff095c116423210f6d1c360895007609ac1687033b215d2c48, 
        0x2bec0b2b26501394164224a112fd01620ec22108030501862bd61c1401ba0961, 
        0x2de0139b0e78258b1fd2126a00f206012a61214e2407001b1c2506601cec03f9, 
        0x268b186a277625fb0bab17860e3e267c2c96213d29ba1c911f4513e0139303ea, 
        0x77805622e4e1f10094d1abd200101ed0cb02b4a149d04901ddc2e6d085f2bd8, 
        0x2910067f1dd32a6f0a9014ab134a0e3411552ffe0c4d2f611cca2f900f4b0876, 
        0x5cc1ce22525144b0a550fd527001c4f1114087e1ec324e2233a0fd906990d24, 
        0x2031273824bd2b800c72151f27b3065e0db614d40b3126bf2468207725832352, 
        0x1dc0dcb13290f910608277f01a41a4a00f30bc8029f244923c11bba22b926a2, 
        0x118d237f27f814f9150728ea015e05e818cb29d22a30263d05cb171b04ef0031, 
        0x129207422e57230e0b6d015b2154284a02d300ae069d24400a5f199a1915254f, 
        0x28f424bf27fe07a2267217fe02400f7b22380d6a00da0b5c28ce093910130bd6, 
        0x50d1d801d5b15352e3c171401a20ebc14d5281216f408e9009c253220800f97, 
        0x20302171048717662c4d2b872a850145249a214f0fed2051028c168617d30127, 
        0x14b1181a0f7405502b511bc126061817063a28571c0f17490a842f5910ca0d01, 
        0x2cbe1850220f1090052723b302c50fce081e045810e207a601b9039a2bdf2012, 
        0x1b780efa18e21eb01a932413292e23ce263a247d169629e32fc10e4802ab099b, 
        0x2800133005292f41228c12ac125a13c10313226703f21aa523ca1fb824991b88, 
        0x27b2009724ea0f75171226382e52062b0c662fcd2533052b22f9185a190f02a5, 
        0x10742c320d6e24e52bb0008e19d00d9518892c8c1c7007a42c160dcc2f102fc7, 
        0x1df117bd0cbf21f117b40e1220112e5c2da408fe01f81f8c16fe12ae1a27242c, 
        0x2be71e4915450f14258604a6211717e621342f6e1ab11161128d1a601d4c1e8e, 
        0x2c0717252bf022471a3b07b526d92b0314c3201613341f1d2df70879234313d7, 
        0x294101901808135421c61ada191b17f82fc90c7f14561a6807c306a60ded028e, 
        0x2b1b03cd1ac62ab207820f27206328102e83013c206d01d417cd0e7e154614db
    ];

    uint256 t = n;
    uint256 m = 1;

    uint256 S;

    assembly ("memory-safe") {
        for {} gt(n, m) {} {
            //while(m<n)
            t := shr(1, t)

            for { let i := 0 } gt(m, i) { i := add(i, 1) } {
                let j1 := shl(1, mul(i, t))
                let j2 := sub(add(j1, t), 1) //j2=j1+t-1;

                //uint256 S = psirev[m+i];
                S := mload(add(psirev, mul(32, shr(4, add(m, i)))))
                S := and(shr(mul(16, and(add(m, i), 0xf)), S), 0xffff)

                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj)

                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mulmod(mload(a_aj), S, q)
                    mstore(a_aj, addmod(U, sub(q, V), q))
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q))
                }
            }
            m := shl(1, m) //m=m<<1
        }
    }
    return a;
}

// NTT_INV as specified by EIP, stateful version
//address apsiinvrev: address of the contract storing the powers of psi^-1
function _ZKNOX_NTTINV(uint256[] memory a, address apsiinvrev) view returns (uint256[] memory) {
    uint256 t = 1;
    uint256 m = n;

    uint256[1] memory S;

    assembly ("memory-safe") {
        for {} gt(m, 1) {} {
            // while(m > 1)
            let j1 := 0
            let h := shr(1, m) //uint h = m>>1;
            for { let i := 0 } gt(h, i) { i := add(i, 1) } {
                //while(m<n)
                let j2 := sub(add(j1, t), 1)
                extcodecopy(apsiinvrev, S, mul(add(i, h), 2), 2) //psi_rev[m+i]
                for { let j := j1 } gt(add(j2, 1), j) { j := add(j, 1) } {
                    let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
                    let U := mload(a_aj) //U=a[j];
                    a_aj := add(a_aj, mul(t, 32)) //address of a[j+t]
                    let V := mload(a_aj)
                    mstore(a_aj, mulmod(addmod(U, sub(q, V), q), shr(240, mload(S)), q)) //a[j+t]=mulmod(addmod(U,q-V,q),S[0],q);
                    a_aj := sub(a_aj, mul(t, 32)) //back to address of a[j]
                    mstore(a_aj, addmod(U, V, q)) // a[j]=addmod(U,V,q);
                } //end loop j
                j1 := add(j1, shl(1, t)) //j1=j1+2t
            } //end loop i
            t := shl(1, t)
            m := shr(1, m)
        } //end while

        for { let j := 0 } gt(mload(a), j) { j := add(j, 1) } {
            //j<n
            let a_aj := add(a, mul(add(j, 1), 32)) //address of a[j]
            mstore(a_aj, mulmod(mload(a_aj), nm1modq, q))
        }
    }

    return a;
}

function _ZKNOX_VECMULMOD(uint256[] memory a, uint256[] memory b) pure returns (uint256[] memory) {
    uint256[] memory res = new uint256[](a.length);
    for (uint256 i = 0; i < n; i++) {
        res[i] = mulmod(a[i], b[i], q);
    }
    return res;
}

//multiply two polynomials over Zq a being in standard canonical representation, b in ntt representation with reduction polynomial X^n+1
//packed input and output (16 chunks by word)
function _ZKNOX_NTT_HALFMUL_Compact(uint256[] memory a, uint256[] memory b, address o_psirev, address o_psi_inv_rev)
    view
    returns (uint256[] memory)
{
    return (
        _ZKNOX_NTT_Compact(
            _ZKNOX_NTTINV(
                _ZKNOX_VECMULMOD(_ZKNOX_NTTFW(_ZKNOX_NTT_Expand(a), o_psirev), _ZKNOX_NTT_Expand(b)), o_psi_inv_rev
            )
        )
    );
}
