// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../src/ZKNOX_IVerifier.sol";
import "../src/ZKNOX_delegate_noproxy.sol";

import "../src/ZKNOX_ethfalcon.sol";
import "../src/ZKNOX_falcon_deploy.sol";

import {console, Test} from "forge-std/Test.sol";

import "forge-std/Vm.sol";

//simple ERC20 for the demonstration
contract ERC20 {
    address public minter;
    mapping(address => uint256) private _balances;

    constructor(address _minter) {
        minter = _minter;
    }

    function mint(uint256 amount, address to) public {
        _mint(to, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal {
        require(msg.sender == minter, "ERC20: msg.sender is not minter"); //comment until delegation works
        console.log("message sender:", msg.sender);
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
    }

    function _acknowledge(bytes memory data) public pure returns (string memory res) {
        return string(abi.encodePacked(data, "\n was successfully signed!"));
    }
}

contract CallExecutor {
    function executeCall(
        address verifier,
        address token,
        bytes memory data,
        uint256 value,
        bytes memory salt,
        uint256[] memory s2
    ) external {
        console.log("Verifier:", verifier);
        console.log("Token:", token);
        console.logBytes(data);
        console.log("Value:", value);
        console.logBytes(salt);
        console.log("S2 Length:", s2.length);

        // Direct `call`, ensuring Verifier's storage is accessed instead of Alice's
        (bool success, bytes memory returnData) = verifier.call(
            abi.encodeWithSignature("transact(address,bytes,uint256,bytes,uint256[])", token, data, value, salt, s2)
        );
        require(success, "Call to Verifier failed");
    }
}

contract SignDelegationTest is Test {
    // Alice's address and private key (EOA with no initial contract code).
    address payable ALICE_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    address constant BOB_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    // Deployer's address and private key (used to deploy contracts).
    address private constant DEPLOYER_ADDRESS = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    uint256 private constant DEPLOYER_PK = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;

    // The contract that Alice will delegate execution to.

    ZKNOX_ethfalcon public falcon;
    ZKNOX_Verifier Verifier;

    // ERC-20 token contract for minting test tokens.
    ERC20 public token;

    function setUp() public {
        // Deploy the delegation contract (Alice will delegate calls to this contract).

        falcon = new ZKNOX_ethfalcon();
        // public key in ntt form
        // forgefmt: disable-next-line
        uint256[32] memory tmp_pkc = [20377218425118340445148364134355217251962993606936992273331839780054216280849, 20121106827228450321124896615938334719918113760150351437528659189176262990636, 10067497595444039977213793634597611854404700659079271442444950951559432116521, 8117003418140413121709569530562717039471558017795389997976077490386494167285, 19719916617578783495479977733846345663822541355599584111604787561804371332299, 12011255695358364119082992510081379197681548345148896992583517862986064267371, 1413712800155248155901989741415704580119744515670156265477932184210522442954, 20205896941262413308936850117551422118594142119900192427257346204109575433582, 3486279541225130755598501027003998051985801747561740177288468626060198090459, 15477599456049069393051346514952035991054078301113692636739851820730251809819, 21156392022423827010876847021244058034030321298933336763476969617428294271271, 2908341131797448574919302622375649436059983246466303686691800726354050296280, 4014285105619800009931504325676093765338451832744274077688243007139640906463, 17525386234073442601006363277175078033276096227970594283065994928074709206070, 9399682681199319758356271164177409471029167726563817053939019373865509324066, 14497266053893643950060558685941531408969726991430751449270004178102628913394, 20001018922134128765022849593872125843127919031255693298563962888117505231302, 20223399471737868067964408671262891234552388541376818065834177454291358723391, 11076429199706617732593752467897544427206591530047673604493842949459150906661, 10003914827585439734433133640025401879385317162577084551224105445404031001782, 20818841785974240140489196577114322827962289517719106191109136290716168037702, 9930008312479770233251082269305959959461466299666759427058224003186584853639, 13961923764749961571138036653552925829425897028586292322709756121414948556716, 1865847632959804051511238296007895164923970314748517688837335778369740540589, 9619029050213147645610307806665071441731316717663787766260527940528214317525, 14242850992292404983847270889619711734347852346434510691917062411771622728876, 14741088360075140317883502213566092308263093099494020005957065598182206670698, 450741599221347172965973222014483009289616792068532398266398440365899262013, 18781682460599299134542238039348179607304289110944838378016618837639364477280, 9945663145577743462232497392336568635199398547866845488457561121052707133988, 4434915596203863112439022225522412087141907977885194617923870370615952742502, 9078099396363096043342272050200561246179429816170715912419583083116430298211];
        uint256[] memory pkc = ZKNOX_memcpy32(tmp_pkc);
        uint256 iAlgoID = FALCONSHAKE_ID;

        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.14"));

        address iVerifier_algo = address(falcon);
        address iPublicKey = DeployPolynomial(salty, pkc);

        Verifier = new ZKNOX_Verifier(iAlgoID, iVerifier_algo, iPublicKey);
        console.log("param Verifier:", Verifier.algoID(), Verifier.CoreAddress(), Verifier.authorizedPublicKey());

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new ERC20(ALICE_ADDRESS);
    }
}
