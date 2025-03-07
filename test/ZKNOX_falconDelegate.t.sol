// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../src/ZKNOX_IVerifier.sol";
import "../src/ZKNOX_delegate.sol";

import "../src/ZKNOX_falcon_compact.sol";
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
        require(msg.sender == minter, "ERC20: msg.sender is not minter");
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
    }

    function _acknowledge(bytes memory data) public pure returns (string memory res) {
        return string(abi.encodePacked(data, "\n was successfully signed!"));
    }
}

contract SignDelegationTest is Test {
    // Alice's address and private key (EOA with no initial contract code).
    address payable ALICE_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    uint256 constant ALICE_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    address constant BOB_ADDRESS = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    uint256 constant BOB_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    // The contract that Alice will delegate execution to.
    ZKNOX_Verifier public implementation;
    ZKNOX_falcon_compact public falcon;

    // ERC-20 token contract for minting test tokens.
    ERC20 public token;

    function setUp() public {
        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new ZKNOX_Verifier();
        falcon = new ZKNOX_falcon_compact();
        // public key in ntt form
        // forgefmt: disable-next-line
        uint256[32] memory tmp_pkc=[uint256(9807818718891730533966615164509575764017151053524099258423976834772553965140),18340098138125467691447337077959785268149994316939452976998993957504853156265,5198133703327284157071422809205815024336408019642137871855761911766001193757,885309680723773951581445950479448442138188963959751701993810286786334563851,19751655564167833205324936936214418086799632798155386652828683172706408935156,13449342659324330278443856651216754520591114337785977560380735844903743330507,21412685081650650572110719760616900735599281269400856811705495088893808813464,7182455876228287393000419492025555097227813236263190704105821148459893329094,10346702731445215087289400465904665036614373649415073766421551882524955579599,2602661461191686318241399797978336432747493635009153906211421228123447493354,17460152192629988224191839342813524149690975760517934797656766276578763941977,8030501380784039896959436505501001505082538439109709855711095179607370313313,1869334252111587522914549075648788783845949858255579782083590402809098144636,17244605423862552671483849252199675991941590481856488840270787535924580718702,11336265795525104660827282529254071061160673084427642199020414766362588092858,7834392541464967164445071157396824232455621343468123833119795953667476294495,19320749074383776626289869794062002119037822327089474229301777373758894647631,15804769950401279065265498737970159234892108086909038079651927057616326110849,5524941774629792613265643604106102575196474389604272009945361978094039402215,7912189081096546922096985544357356245951107957167270713824777693799477413938,9251517013408700470756725384748473476160720415021619476382719063671064631329,980629886819687668154444089811786886341348988887074213615781934824155389444,5940413397816454703448409408340853562548545866597888595192275835122337254858,3477241430632946704913201778186656752154449432278581298631128816987460934160,19684655324690250642900619926419342622662744597902662173890575167707890264962,21136817025198787960771334147393601715672137869525072998232149469960570804861,715695489957163697708304262996430301414652155424663974257962371003055997411,779487062625276624243092988713096201766390140956957709636694708471170673149,18108615907818392958604720912508457986590141052566906373861374637494342583430,4888923900533397196030088094647918125568719406578813186855259309838660932599,20133355404703468652353168553951350193203296046835794955257435485399706185274,6958150576137026963644397829477422234280792505821200919066265083919800276574];
        uint256[] memory pkc = ZKNOX_memcpy32(tmp_pkc);
        uint256 iAlgoID = FALCONSHAKE_ID;

        address a_psirev;
        address a_psiInvrev;
        bytes32 salty = keccak256(abi.encodePacked("ZKNOX_v0.14"));
        (a_psirev, a_psiInvrev) = Deploy(salty);
        falcon.update(a_psirev, a_psiInvrev); //update falcon with precomputed tables

        ZKNOX_Verifier Verifier_logic = new ZKNOX_Verifier{salt: salty}();

        address iVerifier_algo = address(falcon);
        address iPublicKey = DeployPolynomial(salty, pkc);

        bytes memory initData =
            abi.encodeWithSignature("initialize(uint256,address,address)", iAlgoID, iVerifier_algo, iPublicKey); //uint256 iAlgoID, address iVerifier_logic, address iPublicKey

        ZKNOX_Verifier_Proxy proxy = new ZKNOX_Verifier_Proxy(address(Verifier_logic), initData);

        ZKNOX_Verifier Verifier = ZKNOX_Verifier(address(proxy));

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new ERC20(ALICE_ADDRESS);
    }

    function testSignAndAttachDelegation() public {
        // Construct a single transaction call: Mint 100 tokens to Bob.
        //SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, BOB_ADDRESS));
        //calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Alice signs and attaches the delegation in one step (eliminating the need for separate signing).
        vm.signAndAttachDelegation(address(implementation), ALICE_PK);

        // Verify that Alice's account now temporarily behaves as a smart contract.
        bytes memory code = address(ALICE_ADDRESS).code;
        require(code.length > 0, "no code written to Alice");

        // As Bob, execute the transaction via Alice's temporarily assigned contract.
        vm.broadcast(BOB_PK);

        //Verifier.transact(address(token), data, 0 ); the goal, when we have the signer

        // Verify Bob successfully received 100 tokens.
        //vm.assertEq(token.balanceOf(BOB_ADDRESS), 100);
    }
}
