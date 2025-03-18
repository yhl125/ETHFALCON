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
///* FILE: ZKNOX_falcon.sol
///* Description: shake XOF function  tests
/**
 *
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import "../src/ZKNOX_shake.sol";
import {Test, console} from "forge-std/Test.sol";

contract ZKNOX_ShakeTest is Test {
    ZKNOX_shake shake = new ZKNOX_shake();

    function test_F1600Zero() public view {
        uint64[25] memory zeroes = [uint64(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

        // forgefmt: disable-next-line
        uint64[25] memory TEST_F1600_ZERO = [
            0xF1258F7940E1DDE7,
            0x84D5CCF933C0478A,
            0xD598261EA65AA9EE,
            0xBD1547306F80494D,
            0x8B284E056253D057,
            0xFF97A42D7F8E6FD4,
            0x90FEE5A0A44647C4,
            0x8C5BDA0CD6192E76,
            0xAD30A6F71B19059C,
            0x30935AB7D08FFC64,
            0xEB5AA93F2317D635,
            0xA9A6E6260D712103,
            0x81A57C16DBCF555F,
            0x43B831CD0347C826,
            0x01F22F1A11A5569F,
            0x05E5635A21D9AE61,
            0x64BEFEF28CC970F2,
            0x613670957BC46611,
            0xB87C5A554FD00ECB,
            0x8C3EE88A1CCF32C8,
            0x940C7922AE3A2614,
            0x1841F924A2C509E4,
            0x16F53526E70465C2,
            0x75F644E97F30A13B,
            0xEAF1FF7B5CECA249
        ];

        uint64[25] memory res = shake.F1600(zeroes);

        for (uint256 i = 0; i < 25; i++) {
            assertEq(res[i], TEST_F1600_ZERO[i]);
        }
    }

    function test_absorb() public view {
        uint64[25] memory state;
        uint8[200] memory buff;

        //vector of size 136 from official kats
        bytes memory message =
            hex"B32D95B0B9AAD2A8816DE6D06D1F86008505BD8C14124F6E9A163B5A2ADE55F835D0EC3880EF50700D3B25E42CC0AF050CCD1BE5E555B23087E04D7BF9813622780C7313A1954F8740B6EE2D3F71F768DD417F520482BD3A08D4F222B4EE9DBD015447B33507DD50F3AB4247C5DE9A8ABD62A8DECEA01E3B87C8B927F5B08BEB37674C6F8E380C04";

        // forgefmt: disable-next-line
        uint64[25] memory expected=[0xf2a3a3057654e665,0xce044847fc85f48e,  0xec3bd70f31a2866a,  0x7bada64d3aa28d05,  0xdf2d6ae3aa215523,  0x18b3f802c1c29a3f,  0x6044c64141c18ca1,  0x867be8cca2f1a54,  0x73773b337ce4e5eb,  0x7b8b093e6cc376c6,  0x3ed5eb2ef9295a2a,  0xd6ab08c040f891d2,  0x329ec3f446ae8bc6,  0x21ce09a9142a7a7d,  0xc5d90ada910c2965,  0xefa939add08954f4,  0xdfd33eee70e98a5a,  0x69c21fbc22c1f12a,  0x99e8f946ed7c1708,  0xc47ef08b0c9f3f9f,  0x5a102b80ec0fb414,  0x52d66d1377cf6219,  0x3a79068ab1f1288,  0x17a59fb049fd9130,  0x9fccb95c262e9e76];

        (buff, state) = shake.absorb(0, buff, state, message);

        for (uint256 i = 0; i < 25; i++) {
            assertEq(state[i], expected[i]);
        }
    }
}
