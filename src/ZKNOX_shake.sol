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
///* Description: shake XOF function implementation
/**
 *
 */
// SPDX-License-Identifier: MIT
//this is a direct translation from https://github.com/coruus/py-keccak/blob/master/fips202/keccak.py
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";

contract ZKNOX_shake {
    uint256 constant _RATE = 136;

    // """Rotate uint64 x left by s.""
    function rol64(uint256 x, uint256 s) public pure returns (uint64) {
        return (uint64)(x << s ^ (x >> (64 - s)));
    }

    function F1600(uint64[25] memory state) public pure returns (uint64[25] memory) {
        // forgefmt: disable-next-line
        uint256[24] memory _KECCAK_PI = [uint256(10), 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4, 15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1];
        // forgefmt: disable-next-line
        uint64[24] memory _KECCAK_RC = [uint64(0x0000000000000001), 0x0000000000008082,0x800000000000808a,0x8000000080008000,0x000000000000808b, 0x0000000080000001,0x8000000080008081, 0x8000000000008009,0x000000000000008a, 0x0000000000000088,0x0000000080008009, 0x000000008000000a,0x000000008000808b, 0x800000000000008b,0x8000000000008089, 0x8000000000008003,0x8000000000008002, 0x8000000000000080,0x000000000000800a, 0x800000008000000a,0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008];
        // forgefmt: disable-next-line
     uint256[24] memory _KECCAK_RHO =[uint256(1), 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14, 27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44];

        uint64[5] memory bc = [uint64(0), 0, 0, 0, 0];

        for (uint256 i = 0; i < 24; i++) {
            console.log("%x", state[i]);
        }

        for (uint256 i = 0; i < 24; i++) {
            //range(24):
            uint64 t;
            //# Parity
            for (uint256 x = 0; x < 5; x++) {
                //range(5):
                bc[x] = 0;
                for (uint256 y = 0; y < 25; y += 5) {
                    // range(0, 25, 5):
                    bc[x] ^= state[x + y];
                }
            }
            //# Theta
            for (uint256 x = 0; x < 5; x++) {
                //range(5):
                t = bc[addmod(x, 4, 5)] ^ rol64(bc[addmod(x, 1, 5)], 1);
                for (uint64 y = 0; y < 25; y += 5) {
                    // in range(0, 25, 5):
                    state[y + x] ^= t;
                }
            }

            //# Rho and pi
            t = state[1];
            for (uint256 x = 0; x < 24; x++) {
                bc[0] = state[_KECCAK_PI[x]];
                state[_KECCAK_PI[x]] = rol64(t, _KECCAK_RHO[x]);
                t = bc[0];
            }

            for (uint256 y = 0; y < 25; y += 5) {
                // in range(0, 25, 5):
                for (uint256 x = 0; x < 5; x++) {
                    //range(5):
                    bc[x] = state[y + x];
                }
                for (uint256 x = 0; x < 5; x++) {
                    //range(5):
                    state[y + x] = bc[x] ^ ((bc[addmod(x, 1, 5)] ^ 0xffffffffffffffff) & bc[addmod(x, 2, 5)]);
                }
                state[0] ^= _KECCAK_RC[i];
            }
        } //end loop i
        return state;
    } //end F1600

    function absorb(uint256 i, uint8[200] memory buf, uint64[25] memory state, bytes memory input)
        public
        pure
        returns (uint8[200] memory bufout, uint64[25] memory stateout)
    {
        uint256 todo = input.length;

        console.log("todo=", todo);
        uint256 index = 0;
        while (todo > 0) {
            uint256 cando = _RATE - i;
            uint256 willabsorb = (cando < todo) ? cando : todo;
            console.log("cndo=", cando);
            console.log("willabsorb=", willabsorb);

            for (uint256 j = 0; j < willabsorb; j++) {
                buf[i + j] ^= uint8(input[index + j]);
            }
            i += willabsorb;

            console.log("i=", i);
            if (i == _RATE) {
                console.log("call to permute");
                state = permute(buf, state);
                for (uint256 j = 0; j < 200; j++) {
                    buf[j] = 0;
                }
                i = 0;
            }
            todo -= willabsorb;
            index += willabsorb;
        }

        return (buf, state);
    }

    function update(
        bool _SPONGE_ABSORBING,
        uint256 i,
        uint8[200] memory buf,
        uint64[25] memory state,
        bytes memory input
    ) public pure returns (uint64[25] memory stateout) {
        if (_SPONGE_ABSORBING == false) {
            state = permute(buf, state);
        }
        absorb(i, buf, state, input);
    }

    function squeeze(uint256 i, uint8[200] memory buf, uint64[25] memory state, uint256 n)
        public
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(n);
        uint256 tosqueeze = n;
        uint256 index = 0;
        while (tosqueeze > 0) {
            uint256 cansqueeze = _RATE - i;
            uint256 willsqueeze = (cansqueeze < tosqueeze) ? cansqueeze : tosqueeze;
            for (uint256 j = 0; j < willsqueeze; j++) {
                output[index + j] = bytes1(uint8(state[i + j]));
            }
            i += willsqueeze;
            if (i == _RATE) {
                permute(buf, state);
            }
            tosqueeze -= willsqueeze;
            index += willsqueeze;
        }
        return output;
    }

    function permute(uint8[200] memory buf, uint64[25] memory state)
        internal
        pure
        returns (uint64[25] memory stateout)
    {
        console.log("buffer:");
        for (uint256 i = 0; i < 200; i++) {
            console.log("%x", buf[i]);
        }

        //require a 64 bits swap
        for (uint256 j = 0; j < 200; j++) {
            state[j / 8] ^= uint64(buf[j]) << (((uint8(j & 0x7) << 3)));
        }
        // Call F1600 Keccak permutation function here
        state = F1600(state);

        for (uint256 j = 0; j < 200; j++) {
            buf[j] = 0;
        }

        return state; //zeroization of buf external to this function
    }

    //to be yuled
    function pad(uint256 i, uint8[200] memory buf) internal view returns (uint8[200] memory bufout) {
        buf[i] ^= 0x1f;
        buf[_RATE - 1] ^= 0x80;
        //     F1600(buf);
    }
}
