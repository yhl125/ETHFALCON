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
///* FILE: HashToPoint.sol
///* Description: Compute Negative Wrap Convolution NTT as specified in EIP-NTT
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";

function splitToHex(bytes32 x) pure returns (uint16[16] memory) {
    // splits a byte32 into hex
    uint16[16] memory res;
    for (uint256 i = 0; i < 16; i++) {
        res[i] = uint16(uint256(x) >> ((15 - i) * 16));
    }
    return res;
}

function hashToPointZKNOX(bytes memory salt, bytes memory msgHash, uint256 q, uint256 n)
    pure
    returns (uint256[] memory c)
{
    uint256 k = (1 << 16) / q;
    bytes32 state;
    uint64 counter;
    bytes memory buffer;
    bytes32 outBuffer;
    uint8 outBufferPos;
    bool outBufferValid;

    counter = 0;
    outBufferPos = 0;
    outBufferValid = false;

    // Inject
    buffer = abi.encodePacked("", abi.encodePacked(msgHash, salt));
    // Flip
    state = keccak256(buffer);

    uint256 kq = k * q;
    uint256 t;
    c = new uint256[](512);
    uint256 i = 0;
    while (i < n) {
        assembly {
            mstore(add(buffer, 32), 0)
        }

        buffer = new bytes(2);
        uint256 offset = 0;
        // Use any remaining bytes in the output buffer first
        while (outBufferValid && outBufferPos < 32 && offset < 2) {
            buffer[offset] = outBuffer[outBufferPos];
            outBufferPos++;
            offset++;
        }
        // Generate two blocks
        while (offset < 2) {
            outBuffer = keccak256(abi.encodePacked(state, abi.encodePacked(counter)));
            outBufferPos = 0;
            outBufferValid = true;
            while (outBufferPos < 32 && offset < 2) {
                buffer[offset] = outBuffer[outBufferPos];
                outBufferPos++;
                offset++;
            }
            counter++;
        }

        assembly {
            t := mload(add(buffer, 32))
        }
        t = t >> (256 - 16);
        if (t < kq) {
            c[i] = t % q;
            i++;
        }
    }
}

//Use for Poc only, as this XOF doesn't respect separation domain for input and output of internal state
//CVETH-2025-080203
function hashToPointTETRATION(bytes memory salt, bytes memory msgHash, uint256 q, uint256 n)
    pure
    returns (uint256[] memory)
{
    uint256[] memory hashed = new uint256[](512);
    uint256 i = 0;
    uint256 j = 0;
    bytes32 tmp = keccak256(abi.encodePacked(msgHash, salt));
    uint16[16] memory sample = splitToHex(tmp);
    uint256 k = (1 << 16) / q;
    uint256 kq = k * q;
    while (i < n) {
        if (j == 16) {
            tmp = keccak256(abi.encodePacked(tmp));
            sample = splitToHex(tmp);
            j = 0;
        }
        if (sample[j] < kq) {
            hashed[i] = sample[j] % q;
            i++;
        }
        j++;
    }
    return hashed;
}
