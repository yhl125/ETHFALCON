// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "../lib/forge-std/src/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import "../src/ZKNOX_falcon_compact.sol";
import "../src/ZKNOX_precompute_gen.sol";

//deploy the precomputed tables for psirev and psiInvrev
contract Script_Deploy_psirev is BaseScript {
    // SPDX-License-Identifier: MIT

    function run() external {
        vm.startBroadcast();

        address a_psirev;
        address a_psiInvrev;
        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.1"));
        (a_psirev, a_psiInvrev) = Deploy(salty);

        ZKNOX_falcon_compact ETHFALCON = new ZKNOX_falcon_compact{salt: salty}();
        ETHFALCON.update(a_psirev, a_psiInvrev);

        vm.stopBroadcast();
    }
}
