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
///* FILE: ZKNOX_falcon_encodings.sol
///* Description: Decompression function of falcon verification
/**
 *
 */
import "./ZKNOX_falcon_utils.sol";
import {Test, console} from "forge-std/Test.sol";

uint256 constant max_in_len = 666;

// translation of https://github.com/zhenfeizhang/falcon-go/blob/main/c/codec.c with minor tricks, and return in [0..q-1] instead of centered
function _decompress_sig(bytes memory buf) pure returns (uint256[] memory) {
    uint256[] memory x = new uint256[](512);

    uint32 acc = 0;
    uint256 acc_len = 0;
    uint256 v = 0;

    for (uint256 u = 0; u < n; u++) {
        uint256 b;
        uint256 s;
        uint256 m;

        /*
		 * Get next eight bits: sign and low seven bits of the
		 * absolute value.
		 */
        if (v >= max_in_len) {
            revert("too long");
        }
        acc = (acc << 8) | uint32(uint8(buf[v]));
        v = v + 1;
        b = acc >> acc_len;
        s = b & 128;
        m = b & 127;

        /*
		 * Get next bits until a 1 is reached.
		 */
        for (;;) {
            if (acc_len == 0) {
                /*if (v >= max_in_len) {
					revert("too long");-> tested at end of function
				}*/
                acc = (acc << 8) | uint32(uint8(buf[v]));
                v = v + 1;
                acc_len = 8;
            }

            acc_len--;
            if (((acc >> acc_len) & 1) != 0) {
                break;
            }

            assembly {
                //if eq(0, and(1, shr(acc_len, acc)) )   {break}
                m := add(m, 128) //m += 128;
            }
        }

        if (m > 2047) {
            revert("coeff to big");
        }
        /*
		 * "-0" is forbidden.
		 */
        //	if ( ((s==0) && (m==0)) ) {
        //		revert("incorrect zero encoding");
        //	}

        if (s == 0x80) {
            x[u] = q - m;
        } else {
            x[u] = m;
        }

        //  console.log("u=%d, s=%x, x=",u, s, m);
    } //end loop u

    if (v >= max_in_len) {
        revert("too long");
    }

    return x;
}

function decompress_kpub(bytes memory buf) pure returns (uint256[] memory){
    uint256[] memory x = new uint256[](512);
    uint32 acc = 0;
    uint256 acc_len = 0;
    uint256 u = 0;
    uint in_len = ((n * 14) + 7) >> 3;
    uint cpt=0;

    while(u<n){
        acc = (acc << 8) | uint32(uint8(buf[cpt]));
        cpt++;

		acc_len += 8;
		if (acc_len >= 14) {
			uint32 w;

			acc_len -= 14;
			w = (acc >> acc_len) & 0x3FFF;
			if (w >= 12289) {
				revert("wrong coeff");
			}
			x[u] = uint256(w);
            u++;
		}
        if ((acc & ((1 << acc_len) - 1)) != 0) {
		    revert();
	    }
    }

    return x;
}

    /*
	 * Decode NIST KAT made of
     * the encoded public key:0x09+ public key compressed value
     * the signature bundled with the message. Format is:
	 *   signature length     2 bytes, big-endian
	 *   nonce                40 bytes
	 *   message              mlen bytes
	 *   signature            slen bytes
	 */
function decompress_KAT(bytes memory pk, bytes memory sm) pure returns (uint256[] memory ntth, uint256[] memory s2){
    /*
	 * Decode public key.
	 */
	if (pk[0] != 0x09) {
		revert("wrong public key encoding");
	}


}