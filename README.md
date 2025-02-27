# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 

## EXAMPLE
In this section, a signature is generated using Python and verified using Solidity.
```bash
cd python-ref
```
The public and private keys are generated using Python:
```bash
# generate public and private keys from polynomials given in a KAT file
./sign_cli.py genkeys --version='falcon' --fixed=1
```
This command prints the public key in Solidity format:
```solidity
// forgefmt: disable-next-line
uint[512] memory pk = [uint(11496), 8750,6367,8513,9698,2801,11184,7720,3044,6551,12169,6495,2608,10601,3965,2608,6931,5266,5015,11190,11904,11241,2735,6906,7831,6600,4500,9359,4245,5436,8774,2589,4561,8983,696,8332,4550,1996,2855,7575,2429,2784,869,12283,7148,11327,8000,2406,9422,7003,9693,10658,1286,7617,240,1465,4821,9727,6893,10912,4320,10947,11575,5020,1246,9103,12228,982,1652,5442,5066,1984,5969,10958,11600,6828,10785,9074,11562,8427,7384,10225,3146,9884,227,10528,6914,7012,11418,618,2344,2442,12118,1590,4659,9,6054,2974,1062,7889,7428,11552,10955,3953,11650,5488,3360,6419,2018,7855,11937,10273,11760,10619,2946,9827,1391,5288,10081,7879,436,2821,10976,4719,3805,9319,9630,2921,4919,11006,8476,822,3362,6488,3539,2966,9066,11199,3581,6766,9874,5432,8230,1904,10886,9536,650,3017,8013,3273,11999,10043,9288,8661,3001,9709,1944,7455,3436,5174,887,5047,7710,10546,5349,11586,10870,6055,587,5456,2913,7852,4569,89,11242,6656,7772,5474,11556,1074,5017,8253,6103,11848,4716,6126,4405,5651,6845,369,11740,7603,7746,7584,915,6450,9542,10494,256,9124,4106,8698,7618,1531,11543,9513,1711,1120,6401,11319,947,7814,4649,7342,10521,1379,7114,4336,6053,6221,1914,3752,8195,10946,5208,1259,11370,6416,5131,5381,8682,7596,8281,2484,11339,11788,7058,5553,2273,6449,608,11847,4196,2901,12045,6603,3256,9934,7986,8114,11513,907,8637,6623,4668,4038,11237,5537,4283,6388,6134,8930,2128,2128,2963,7004,8973,7762,171,10591,7196,745,2586,2633,10421,8891,3400,4224,2007,4723,10362,2104,8976,722,11441,2652,6325,6241,2988,11748,7855,9040,7088,9407,9770,867,2077,4362,12110,1082,1850,4862,4330,10985,5379,10483,7677,2619,2355,3252,2103,6398,11488,3782,3245,9556,5907,4738,8334,8587,6139,5343,6495,8498,7104,10335,8532,10159,8308,9264,10616,12269,4354,1430,4838,1508,10559,2651,6956,11497,8752,1131,2791,4011,4253,3438,9498,5714,10445,10070,5480,5019,6473,7725,1261,3066,198,7815,2246,3496,8064,739,5866,5569,11456,2244,668,8395,5445,2772,4408,9293,11014,761,3718,11571,3404,368,3579,10321,6736,11875,10187,529,280,2368,2568,4932,6205,7260,7792,7205,11919,1381,11963,3502,11363,7457,9950,4892,10373,5957,10007,711,11549,2571,8529,8934,5748,4109,6209,5302,5566,1970,3825,7545,351,11519,7545,2503,3567,1449,2813,4183,7617,12054,6684,8500,1397,2228,4403,10069,7801,4417,9204,1364,3084,3708,8282,9585,5338,10093,4234,6005,8209,1525,3841,5204,2613,2267,3108,8948,8153,7531,7324,9187,2570,684,4422,5060,8768,11619,3214,707,7175,5379,169,4774,6508,6510,3021,11514,179,4509,3931,3453,7772,4992,4043,12029,8039,9766,8752,5730,5298,2055,8370,9754,2872,731,9288,2970,315,5281,10632,4920,609,5117,4981,3040,9677,1530,695,10176,5260,3336,2120,6452,6772,3911,5640,4868];
```
The signature is computed from the private key (stored in `private_key.pem`):
```bash
# generate a signature for the message "This is a demo" using a fixed salt
./sign_cli.py sign --privkey='private_key.pem' --message="This is a demo" --version='falcon' --fixed=1
```
This commands prints the signature in the Solidity format:
```solidity
// Solidity raw signature:
// s2
// forgefmt: disable-next-line
uint[512] memory s2 = [uint(137), 24, 12191, 333, 11, 12027, 206, 189, 12165, 12233, 66, 303, 12135, 12243, 298, 160, 12166, 194, 12118, 113, 157, 12160, 113, 12050, 173, 12203, 12238, 12180, 81, 12280, 22, 193, 12033, 82, 12111, 12004, 12085, 252, 181, 11976, 12252, 12236, 12283, 12174, 6, 12241, 22, 12164, 12181, 110, 12150, 12216, 12145, 246, 104, 214, 95, 12244, 12147, 34, 11983, 73, 129, 239, 204, 12047, 12265, 194, 12206, 12245, 28, 12205, 12125, 149, 12222, 486, 81, 42, 12284, 12269, 12255, 286, 12189, 12229, 12088, 246, 111, 12173, 22, 12124, 195, 250, 113, 73, 39, 12288, 12025, 53, 12257, 11984, 12157, 12285, 12190, 109, 12253, 11983, 32, 55, 234, 12237, 99, 111, 342, 12284, 142, 59, 50, 102, 290, 12276, 12099, 12225, 11843, 12079, 107, 71, 55, 12279, 12165, 70, 279, 86, 12004, 198, 71, 122, 12252, 145, 12267, 12130, 83, 327, 132, 12241, 12228, 59, 83, 12023, 12221, 12185, 78, 337, 56, 111, 12210, 62, 12129, 12113, 275, 68, 12131, 4, 12185, 85, 115, 12216, 12253, 11, 101, 12007, 2, 231, 12018, 18, 40, 196, 69, 12165, 12252, 12165, 88, 135, 61, 12192, 63, 361, 55, 12273, 12221, 11, 389, 12090, 12183, 229, 50, 166, 7, 80, 104, 484, 16, 11939, 315, 44, 382, 27, 12215, 12153, 12, 12280, 12124, 12165, 12094, 12194, 399, 12262, 43, 279, 12186, 121, 304, 12120, 146, 12248, 12114, 212, 12081, 157, 12232, 39, 107, 11980, 309, 12146, 12130, 212, 12146, 177, 12248, 12221, 174, 11955, 12179, 167, 57, 12252, 12073, 12146, 11940, 207, 12248, 12137, 26, 12082, 12251, 175, 200, 114, 11945, 12045, 39, 194, 12049, 220, 12191, 67, 77, 154, 232, 226, 103, 12267, 253, 15, 244, 12166, 70, 12243, 156, 12227, 12234, 12229, 102, 63, 12219, 12217, 128, 26, 12252, 12146, 12017, 12266, 86, 429, 12150, 108, 12110, 93, 12031, 217, 83, 120, 211, 34, 11976, 12139, 12139, 9, 12160, 244, 114, 68, 12037, 11902, 3, 12149, 12229, 12197, 19, 139, 301, 12263, 129, 147, 124, 12012, 171, 12219, 12076, 11963, 188, 12146, 12035, 87, 12097, 12248, 12240, 255, 12109, 12222, 12187, 19, 183, 12141, 33, 96, 12287, 28, 2, 12105, 279, 39, 405, 55, 12034, 30, 60, 313, 12285, 181, 194, 12244, 153, 100, 12107, 12228, 12252, 16, 134, 256, 37, 195, 333, 12083, 12123, 12189, 188, 333, 12121, 12142, 12255, 12115, 12029, 261, 60, 341, 12121, 12146, 157, 86, 236, 11900, 2, 75, 12261, 12114, 19, 116, 11818, 12183, 126, 12209, 13, 11937, 12201, 12220, 50, 12031, 437, 173, 152, 12270, 12186, 86, 469, 91, 12070, 24, 12242, 11784, 12247, 12235, 51, 12257, 11959, 12113, 33, 12098, 184, 12184, 437, 361, 12195, 11811, 12270, 12273, 109, 12127, 526, 12187, 40, 90, 12132, 318, 12224, 12280, 205, 12008, 12062, 12167, 87, 63, 17, 12100, 28, 12108, 12276, 233, 232, 54, 177, 246, 12258, 12133, 423, 12201, 12228, 12207, 89, 98, 25, 226, 6, 12089, 12087, 12188, 45, 139, 12166, 12270, 12173, 12265, 42, 12049, 66, 57, 497, 12081, 114, 12174, 12181, 61, 12104, 12226, 156, 78, 12113, 11940, 6, 12268, 12278, 12077, 22, 73, 12134, 111, 12284, 268, 12060, 259, 380, 12136];

sig.salt = "\x0e\x14\x4c\x47\xc6\x5a\xfe\x7d\x97\xc6\x54\x2a\x49\x83\x45\x5a\x77\x98\xd2\x06\xcc\x7b\xa2\x33\x7d\xe9\xb7\x08\x13\x37\x6c\xc4\xef\xcf\x49\x58\x62\xb3\x9a\x99"; 
```
The signature can be verified in Solidity as follows:
```bash
cd ../
# Use foundry_profile=lite for faster computation (but the gas is not optimized)
FOUNDRY_PROFILE=lite forge test --match-test=Example
```
The verification passes:
```solidity
Ran 1 test for test/example.t.sol:ExampleTest
[PASS] test_ExampleVerification()
Suite result: ok. 1 passed; 0 failed; 0 skipped; 
```

## SPECIFICATION
The repository implements several tweaked version of FALCON, optimized for different constraints. In the rest of this note, the following versions will be distinguished:


<table>
  <tr>
    <th>Algorithm</th>
    <th>Specification</th>
    <th>Description</th>
    <th>Implementation Status </th>
  </tr>
  <td>FALCON</td>
  <td>NIST</td>
  <td>The original FALCON NIST submission</td>
  <td> TBD (Missing SHAKE)</td>
    </tr>
  <td>FALCONREC</td>
  <td>NIST</td>
  <td>The original FALCON NIST submission, recovery mode</td>
  <td> TBD (Missing SHAKE)</td>
  </tr>
  <td>FALCON-SOLIDITY</td>
  <td>Tetration </td>
  <td>An EVM Friendly version of FALCON using keccak instead of SHAKE for XOF</td>
  <td> OK </td>
  </tr>
  </tr>
   <td>FALCON-SOLREC</td>
  <td>Tetration </td>
  <td>A  recovery version, compatible with FALCON SOLIDITY XOF</td>
  <td> OK </td>
  </tr>
  <td>FALCONRIP</td>
  <td>ASANSO </td>
  <td>FALCON RIP draft by [ASANSO](https://github.com/asanso/RIPs/blob/master/RIPS/rip-falcon.md) </td>
  <td> WIP </td>
  </tr>
  <td>EPERVIER</td>
  <td>ZKNOX </td>
  <td>An EVM Friendly version of FALCONREC  avoiding expensive operations </td>
  <td> WIP</td>
  </tr>

</table>   

The difference lies mainly in the definition of the inner expandable hash functions (XOF) required in $HashToPoint$ and $H$ (this latest only for recovery).
Those function being non standard, the  code provided by authors is the specification until further notice.
<table>
  <tr>
    <th>Algorithm</th>
    <th> XOF </th>
    <th> H </th>
  </tr>
  <td> FALCON </td>
  <td> SHAKE</td>
  <td> N/A </td>
  </tr>
  </tr>
    <td> FALCON-SOLIDITY </td>
    <td> Keccak-OFB </td>
    <td> N/A </td>
  </tr>
   </tr>
    <td> FALCONRIP </td>
    <td> Keccak-CTR </td>
    <td> N/A </td>
  </tr>
 </tr>
  <td> EPERVIER </td>
  <td> Keccak-CTR (WIP) </td>
  <td> Keccak(NTT(x)) </td>
  </tr>


</table>     

### Falcon 

**Original specification.** 
FALCON refers to the original [specification](https://falcon-sign.info/falcon.pdf), as submitted to NIST. We provide here a simplified description of the signature scheme:
- The public key is a polynomial $h$,
- The signature is given as $(s_2, r)$ where $s_2$ is in compressed format,
- The verification is split as follows:
  - $c\leftarrow HashToPoint(r||m)$,
  - Decompress $s_2$ (reject if it goes wrong),
  - $s_1 \leftarrow c-s_2\times h$,
  - if $(s_1,s_2)$ is short, accept, otherwise, reject.

**Public key recovery mode.**
Falcon specification also includes a public key recovery version. Although it is not present in the standard implementation, it is described in the specification in [Section 3.12](https://falcon-sign.info/falcon.pdf). We denote this version FalconRec and we summarize it here:
- The public key becomes $pk=H(h)$ for some collision-resistant hash function $H$;
- The signature becomes $(s_1, s_2, r)$, where $s_1$ and $s_2$ are in compressed format,
- The verifier accepts the signatures if and only if:
  - $(s_1, s_2)$ is short;
  - $pk==H(s_2^{-1}(HashToPoint(r\mid\mid m)-s_1))$

Note: In the context of ETHEREUM, It is valuable to stick to the `ecrecover` specification. 


### Falcon-Solidity: an EVM-friendly signature

**Tetration implementation.**
FALCON-SOLIDITY refers to the specification of [Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repository. It is important to notice that this implementation is EVM friendly and use a FALCON equivalent implementation using a Keccak XOF instead of SHAKE. It is thus not compliant with [FALCON](https://falcon-sign.info/falcon.pdf) NIST instantiation. While assumingly not degrading the  security it is not compatible with the original specification.

**Optimizations.**
The performance improvement brought by ZKNOX to this version comes from :
-  generic solidity gas cost optimizations (replacing mul by shifts, etc.)
- the replacement of a recursive NTT, by a NWC (Negative Wrap Convolution) specialized one as specified in EIP-NTT following [LN16]. This NTT is twice faster and does not need to store a table of $q$ elements
- the precomputation of the NTT from of the public key to avoid repetitive identical computations for each iteration.


**Uncovered vulnerabilities on Tetration [v1.0](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol).**


| Label                   | Severity | Description               |  Impact |Fix | PR |
|------------------------|---------------------|---------------------|---------------------|---------------------|---------------------|
|CVETH-2025-080201| critical  | salt size is not checked in verification | forge | add salt size checking | [here](https://github.com/Tetration-Lab/falcon-solidity/pull/1)
|CVETH-2025-080202| medium | signature malleability on coefficient signs | malleability | force positive coefficients in s part | [here](https://github.com/Tetration-Lab/falcon-solidity/pull/1)
|CVETH-2025-080203| low | no domain separation of internal state input and output | XOF design infringment | modify FALCON-SOLIDITY XOF specification | TBD


### Epervier: a compact EVM-friendly Falcon with public key recovery mode

**Optimization of FalconRec.**

In order to optimize the verification of FalconRec, we use a classical trick in ZK implementations by providing $s_2^{-1}$ as an extra value (a hint) in the calldata, in the NTT domain (i.e. we provide `ntt(s2Inverse)`). Then, the verifier needs to check that the hint is indeed the inverse of $s_2$:
- The public key remains $pk = H(h)$ for some collision-resistant hash function $H$;
- The signature becomes $σ  =(s_1,s_2,r,ntt(s_2^{-1}))$,
- The verification splits as:
  - $ntt(σ_2)\cdot σ_4 == ntt(1)$,
  - $(σ_1,σ_2)$ is short,
  - $pk==H(intt(σ_4\cdot ntt(HashToPoint(σ_3\mid\mid m)-σ_1)))$.

Finally, the cost of FalconRec verification is dominated by **2NTT + 1iNTT** (1 NTT in step 1, and the rest in step 3).

Note that the check of step one is done in the NTT domain, where $ntt(1)$ is the constant equal to 1 at every poition. It is a simple equality test once $ntt(σ_2)$ is computed.

**Moving the public key in the NTT domain.**

We present here a modification of the public key in order to reduce the verification cost. The public key is moved in the NTT domain in order to save an iNTT in the FalconRec verification. Epervier is summarized as follows:
- Public key: $pk=H(ntt(h))$ for some collision-resistant hash function $H$;
- Signature: $σ = (s_1, s_2, r, ntt(s_2^{-1}))$ 
- The verifier accepts the signatures if and only if:
    - $ntt(σ_2)\cdot σ_4==ntt(1)$;
    - $(σ_1,σ_2)$ is short;
    - $pk==H(σ_4\cdot (ntt(HashToPoint(r\mid\mid m)-σ_1)))$.

Using this verification, we compute only **2NTT** (+ additional hash computations and vectorized arithmetic) for the verification. This matches with the number of NTT in Falcon (without the recovery mode).

We claim that the interest of EPERVIER goes beyond Ethereum ecosystem. For hardware implementations, avoiding a NTTINV reduces the total required gates. Using a pipeline, it also enables to reuse the same NTT circuit inducing only latency of one stage of the implementation.

<!-- 
- the NTT used here is the NWC defined in NTT-EIP
- PRNG_Keccak is a construction that generates the desired output only using keccak (EVM friendly) 
- Defining H as H=ntt(keccak(c) remove to use Inverse NTT, this reduces the surface of hardware implementation. -->


## BENCHMARKS


### Solidity


| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| OK|




### Yul

Upon confirmation of the optimal algorithm for NTT, its critical parts have been implemented in Yul, benefiting from the extcodecopy trick described in 3.3, stack optimization, and variable control.
As there are still experiments, concurrent versions are benched here. 

| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| ZKNOX_falcon_compact.verify       | ZKNOX_NTT      | 1.9 M | OK|
| ZKNOX_falcon_compact.verifyTETRATION       | ZKNOX_NTT      | 2.23M | OK|

**Note on the encoding**: polynomials are encoded as $(a_0 || a_1|| \ldots|| a_k)$, where $P=\sum {a_i}X^i$, the operator || being concatenation, each $a_i$ being encoded on 16 bits. This leads to a representation of $P$ over 32 uint256.


### Python

NTT implementation are benchmarked against Tetration implementation. The implementation enables to select the XOF function and the algorithm to compute NTT (iterative or recursive).

<table>
  <tr>
    <th>n</th>
    <th>Falcon Verification (ZKNox)</th>
    <th>FalconRec Verification (ZKNox)</th>
    <th>Epervier Verification (ZKNox)</th>
  </tr>
    <td>64</td>
    <td>0.3 ms</td>
    <td>0.6 ms</td>
    <td>0.6 ms</td>
  </tr>
  <tr>
    <td>128</td>
    <td>0.6 ms</td>
    <td>1.1 ms</td>
    <td>1.0 ms</td>
  </tr>
  <tr>
    <td>256</td>
    <td>1.2 ms</td>
    <td>2.2 ms</td>
    <td>1.9 ms</td>
  </tr>
  <tr>
    <td>512</td>
    <td>2.8 ms</td>
    <td>4.6 ms</td>
    <td>4.0 ms</td>
  </tr>
  <tr>
    <td>1024</td>
    <td>5.8 ms</td>
    <td>9.6 ms</td>
    <td>8.4 ms</td>
  </tr>
</table> 


## CONCLUSION

This repo provides a highly optimized version of FALCON. Order of magnitudes were gained compared to other implementations. In our search, we also devise a way to implement falcon with recovery without requiring the inverse NTT transformation (only forward).
Despite those efforts, it does not seem plausible to reach operational (below 1M) verification cost. Nevertheless, the provided code allow Account Abtraction using 7702 or 4337 from today.
The architecture also demonstrates that providing NTT would allow an acceptable cost, and provide more genericity and agility in the PQ signature candidate of Ethereum. For this reason [NTT-EIP]() is submitted.

## REFERENCES
- [[EXTCODE COPY TRICK]](https://eprint.iacr.org/2023/939) section 
- [[FALCON]](https://falcon-sign.info/falcon.pdf) Falcon: Fast-Fourier Lattice-based
Compact Signatures over NTRU
- [[NTT-EIP]]() NTT-EIP as a building block for FALCON, DILITHIUM and Stark verifiers 
- [[Tetration]](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) Falcon solidity.
