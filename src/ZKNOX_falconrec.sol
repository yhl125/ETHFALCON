/************************************************************************************************************************************************************************/                                                                                                                                                                          
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
///* FILE: ZKNOX_falconrec.sol
///* Description: verify falcon with recovery signature
/************************************************************************************************************************************************************************/   
// SPDX-License-Identifier: MIT


import {ZKNOX_NTT} from "./ZKNOX_NTT.sol";

//choose the XOF to use here
import "./HashToPoint_tetration.sol";


contract ZKNOX_falconrec {

    //FALCON CONSTANTS
    uint256 constant n = 512;
    uint256 constant sigBound = 34034726;
    uint256 constant sigBytesLen = 666;
    uint256 constant q = 12289;
    uint256 qs1 = 6144; // q >> 1;

    ZKNOX_NTT ntt;

    uint256 constant _ERR_INPUT_SIZE = 0xffffffff01;


    constructor(ZKNOX_NTT i_ntt) {
        ntt = i_ntt;
    }


    struct Signature {
        bytes salt;
        uint256[512] s0;
        uint256[512] s1;
        uint256[512] ntt_sm1; //the ntt of the inverse of s1, provided as a hint
    }

    
    /* A falcon with recovery implementation*/
    function falconrecover(
        bytes memory msgs,
        Signature memory signature
    ) public view returns (address result) {
       

      
        if(signature.salt.length != 40) return false;//CVETH-2025-080201: control salt length to avoid potential forge
        if(signature.s0.length != 512)  return false;//"Invalid s0 length"
        if(signature.s1.length != 512)  return false;//"Invalid s1 length"
        if(signature.ntt_sm1.length != 512)  return false;//"Invalid salt length"

        //(s0,s1) must be short
        uint norm = 0;
        for (uint i = 0; i < n; i++) {
            norm += signature.s0[i] * signature.s0[i];
            norm += signature.s1[i] * signature.s1[i];
        }

        if(norm > sigBound){
            result=0;
        }

        uint256[] memory s1 = new uint256[](512);
        for (uint i = 0; i < 512; i++) {
                s1[i] = uint256(signature.s1[i]);
        }

        uint256[] memory hashed = hashToPoint(msgs, signature.salt, q,n);
        
        uint256[] memory s0 = ntt.ZKNOX_VECSUBMOD(hashed, ntt.ZKNOX_NTT_MUL(s1, h),q);
       
        // normalize s0 // to positive cuz you'll **2 anyway?
        for (uint i = 0; i < n; i++) {
            if (s0[i] > qs1) {
                s0[i] = q - s0[i];
            } else {
                s0[i] = s0[i];
            }
        }

        // normalize s1
        for (uint i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }

        uint norm = 0;
        for (uint i = 0; i < n; i++) {
            norm += s0[i] * s0[i];
            norm += s1[i] * s1[i];
        }

        if(norm > sigBound){
            result=false;
        }
        else{
            result=true;
        }
        return result;
    }


}//end of contract
/************************************************************************************************************************************************************************/  
/*                                                                  END OF CONTRACT                                                                                     */
/************************************************************************************************************************************************************************/  
/* the contract shall be initialized with a valid precomputation of psi_rev and psi_invrev contracts provided to the input ntt contract*/