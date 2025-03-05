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

    function run() external {
        vm.startBroadcast();

        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.17"));

        //those arguments must be passed to the script, like
        uint256 iAlgoID = vm.envUint("_ALGOID");
        address iVerifier_algo = vm.envAddress("_CORESIG_ADD"); // address of the signature verification
        string memory pubstring = vm.envString("_PUBLICKEY");
        uint256[] memory PublicKey = parseUintArray(pubstring); //extracting the public key as uint256[] from input to script

        //deploy the public key into a dedicated contract
        address iPublicKey = DeployPolynomial(salty, PublicKey);

        ZKNOX_Verifier Verifier_logic = new ZKNOX_Verifier{salt: salty}();

        console.log("AlgoID, @Contract, @", iAlgoID, iVerifier_algo, iPublicKey);

        bytes memory initData =
            abi.encodeWithSignature("initialize(uint256,address, address)", iAlgoID, iVerifier_algo, iPublicKey); //uint256 iAlgoID, address iVerifier_logic, address iPublicKey
        ZKNOX_Verifier_Proxy proxy = new ZKNOX_Verifier_Proxy(address(Verifier_logic), initData);
        ZKNOX_Verifier Verifier = ZKNOX_Verifier(address(proxy));

        console.log("adress of core Algorithm: %x", uint256(uint160(Verifier.CoreAddress())));
        console.log("adress of Verifier: %x", uint256(uint160(address(Verifier))));
        console.log("adress of Public Key contract: %x", uint256(uint160(address(Verifier))));

        bytes memory recovered = getBytecode(iPublicKey);
        console.log("recovered PublicKey:");
        console.logBytes(recovered);

        vm.stopBroadcast();
    }
}
