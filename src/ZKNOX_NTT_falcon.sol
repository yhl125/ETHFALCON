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

function _ZKNOX_NTTFW_vectorized(uint256[] memory a, address apsirev) pure returns (uint256[] memory) {
    uint256[32] memory psirev = [
        uint256(0x21dc2610222b0db02386191d04bc066e02d20519102616681be70fcb05c70001),
        0xbbe0ab82462023312d525b225c02c4c2301197013722aba193d139f19a111ef,
        0x109f2b6825310663008c073d1dfe2d2b2416093e1320246e0c132fb010e003e8,
        0x1d3c0de12bdb270b0e800c3f12ee2546090f2b6f03bb0316243b23802ad31c23,
        0x2201105109dd05651b2e1c841f4b29782e2124e700092c0309a42eae169f0220,
        0x33b16870ea42c4813cb089526552f8b20940ce01164095c0082110214fe0b15,
        0x11242b15167b1218097a014e2a6d29612d2823582328282427d813e40b410cd4,
        0xe350d832f7015a60f5c255618ea131a1f7a09f40d362e9e1bc60e6e0e7b2922,
        0x2f901cca20b608761eac2ffe00a023b421cd1cb714ab0a901dd3059206f1067f,
        0x25ac0fd513b20901131f2a3525251bb61ec30b1f1eed087e0fd9233a29680d24,
        0x26a222b914470c402d62244900f32439060808821a4a01a40dcb01dc1cd80f91,
        0x24d026bf0db61b2d0f8a0b9925830caf273820310b442b80065e27b31ae2238f,
        0x2fe60bfa214e2a611c2529a103f91cec0221139b0a7621892f0f06011fd21d97,
        0x2bd613ed096101ba21080ec22cfc01861d04016216420b601c6d09b10b2b2bec,
        0x268b179725fb27760e3e09852456178610bc13e02c171c6e0ec4036b29ba1370,
        0x85f042912252e6d0490149d04b72351154426b420012e1407782a9f1f102e4e,
        0x2a5190f17a70d080ace052b0c660034171209c9062b2e52009727b20b170f75,
        0x2c0f1aa503130d9a10490c3724991479133028002ad82f4113c1125a1d550d75,
        0x451008e226c163103cf1f8d0d6e0b1c1c70285d17782c8c0dcc2c1600f12fc7,
        0x2703025d01f810750bd515da12ae16fe21f10cbf18441210184d0e1201a50ff0,
        0x2e832ec501d4206d15461b2618340e7e153b2ab22b1b2c3420da287f206307f1,
        0xded2d73283e06a61a6814562382003815270e3b191b180929412e7113541808,
        0x2bf00dba03fa172507b51a3b09282b030cbe13d72df7278810e41ccd201614c3,
        0x4a625860eea17e6041a1e4920ed1abc1ea015502f6e2134128d15a11e8e1d4c,
        0x1d80050d12a615350ebc01a218ed01c50acf2f652080206a14d507ef08e916f4,
        0xf7b02401803098f080307a228f40b42223822970b5c00da1013242b07330939,
        0x199a0a5f16ec254f2d2e00ae0bc1296407b70ead015b0b6d2e570cf31d6f0742,
        0x173629d209c405d12b12003105cb18e627f81b081e74237f28ea15072ea305e8,
        0xeb20b670fed0fb02eda182e1686028c176604870e900fd103b42b872ebc057c,
        0x14b117e705500f74260617ea04b01bc1257d2f5923001f3707aa29c71c0f18b8,
        0x61e196b247d263a2fc121b9099b02ab14890efa1151171f06d323ce1a930bee,
        0x1b92c6720122bdf0458081e1f1f07a62d3c0fce05270c4e1f710df218502cbe
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
