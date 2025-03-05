// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "../lib/forge-std/src/Script.sol";
import {BaseScript} from "./BaseScript.sol";

import "../src/ZKNOX_common.sol";
import "../src/ZKNOX_delegate.sol";
import "../src/ZKNOX_precompute_gen.sol";

import {Test, console} from "forge-std/Test.sol";

//this script assumed a successfull deployment of a ISIGVerifier
contract Script_Deploy_Verifier is BaseScript {
    // SPDX-License-Identifier: MIT
    function getBytecode(address target) public view returns (bytes memory code) {
        assembly {
            let size := extcodesize(target) // Get bytecode size
            code := mload(0x40) // Load free memory pointer
            mstore(code, size) // Store length of bytecode
            let ptr := add(code, 0x20) // Pointer to bytecode storage
            extcodecopy(target, ptr, 0, size) // Copy bytecode
            mstore(0x40, add(ptr, size)) // Update free memory pointer
        }
    }

    function splitString(string memory str, string memory delimiter) internal pure returns (string[] memory) {
        uint256 count = 1;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 index = 0;
        bytes memory temp;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[index] = string(temp);
                index++;
                temp = "";
            } else {
                temp = abi.encodePacked(temp, bytes(str)[i]);
            }
        }
        parts[index] = string(temp);
        return parts;
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid uint");
            result = result * 10 + (uint256(uint8(b[i])) - 48);
        }
        return result;
    }

    //a function to parse the public key input as string and convert it to uint256[]
    function parseUintArray(string memory csv) internal pure returns (uint256[] memory) {
        string[] memory parts = splitString(csv, ",");
        uint256[] memory numbers = new uint256[](parts.length);
        for (uint256 i = 0; i < parts.length; i++) {
            numbers[i] = stringToUint(parts[i]);
        }
        return numbers;
    }

    function GetPublicKey(address _from) internal returns (uint256[] memory Kpub) {
        Kpub = new uint256[](32);

        assembly {
            let offset := Kpub

            for { let i := 0 } gt(1024, i) { i := add(i, 32) } {
                //read the 32 words
                offset := add(offset, 32)

                extcodecopy(_from, offset, i, 32) //psi_rev[m+i])
            }
        }
    }

    /* first deployment, including falcon, normally we would like to just pass a IVerifier address*/
    function run() external {
        vm.startBroadcast();

        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.0.0.9"));

        //those arguments must be passed to the script, like
        uint256 iAlgoID = vm.envUint("_ALGOID");
        address iVerifier_algo = vm.envAddress("_CORESIG_ADD"); // address of the signature verification
        string memory pubstring = vm.envString("_PUBLICKEY");
        uint256[] memory PublicKey = parseUintArray(pubstring); //extracting the public key as uint256[] from input to script

        //deploy the public key into a dedicated contract
        address iPublicKey = DeployPolynomial(salty, PublicKey);
        console.log("PublicKey recovered:");
        bytes memory recovered = getBytecode(iPublicKey);
        console.logBytes(recovered);

        ZKNOX_Verifier Verifier_logic = new ZKNOX_Verifier{salt: salty}();

        console.log("AlgoID, @Corealgo, @PubKey", iAlgoID, iVerifier_algo, iPublicKey);

        bytes memory initData =
            abi.encodeWithSignature("initialize(uint256,address,address)", iAlgoID, iVerifier_algo, iPublicKey); //uint256 iAlgoID, address iVerifier_logic, address iPublicKey

        ZKNOX_Verifier_Proxy proxy = new ZKNOX_Verifier_Proxy(address(Verifier_logic), initData); //failing here

        ZKNOX_Verifier Verifier = ZKNOX_Verifier(address(proxy));

        console.log(
            "Verifier State: AlgoID: %x Core:%x Pubkey:%x",
            Verifier.algoID(),
            uint160(Verifier.CoreAddress()),
            uint160(Verifier.authorizedPublicKey())
        );

        ISigVerifier Core = ISigVerifier(Verifier.CoreAddress());

        uint256[] memory nttpk = new uint256[](32);
        //nttpk=Core.GetPublicKey(Verifier.authorizedPublicKey());
        nttpk = GetPublicKey(iPublicKey); //this is correctly extracted, same code duplicated from Core.GetPublicKey();
        uint256[] memory nttpk2 = new uint256[](32);
        nttpk2 = Core.GetPublicKey(Verifier.authorizedPublicKey()); //panic when accessing to nttpk2[i] in the following loop
        console.log("length nttpk2:", nttpk2.length); //the returned length is 0, bug.

        console.log("PublicKey extracted from:%x, %x", iPublicKey, Verifier.authorizedPublicKey());
        for (uint256 i = 0; i < 32; i++) {
            console.log("%x ,%x, %x", PublicKey[i], nttpk[i]);
        }

        vm.stopBroadcast();
    }
}
