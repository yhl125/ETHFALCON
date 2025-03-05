// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "../lib/forge-std/src/Script.sol";
import {BaseScript} from "./BaseScript.sol";

import "../src/ZKNOX_common.sol";
import "../src/ZKNOX_delegate.sol";
import {Test, console} from "forge-std/Test.sol";

//this script assumed a successfull deployment of a ISIGVerifier
contract Script_Deploy_Verifier is BaseScript {
    // SPDX-License-Identifier: MIT

    function run() external {
        vm.startBroadcast();

        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.17"));

        //those arguments must be passed to the script, like
        uint256 iAlgoID = vm.envUint("_ALGOID");
        address iVerifier_algo = vm.envAddress("_CONTRACT"); // address of the signature verification
        address iPublicKey = vm.envAddress("_PUBLICKEY");

        ZKNOX_Verifier Verifier_logic = new ZKNOX_Verifier{salt: salty}();

        console.log("AlgoID, @Contract, @", iAlgoID, iVerifier_algo, iPublicKey);

        bytes memory initData =
            abi.encodeWithSignature("initialize(uint256,address, address)", iAlgoID, iVerifier_algo, iPublicKey); //uint256 iAlgoID, address iVerifier_logic, address iPublicKey
        ZKNOX_Verifier_Proxy proxy = new ZKNOX_Verifier_Proxy(address(Verifier_logic), initData);
        ZKNOX_Verifier Verifier = ZKNOX_Verifier(address(proxy));

        console.log("adress of core Algorithm: %x", uint256(uint160(Verifier.CoreAddress())));

        vm.stopBroadcast();
    }
}
