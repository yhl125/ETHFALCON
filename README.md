# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 


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
  <td> OK </td>
  </tr>
  <td>EPERVIER</td>
  <td>ZKNOX </td>
  <td>An EVM Friendly version of FALCONREC  avoiding expensive operations </td>
  <td> OK</td>
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


## EXAMPLE
In this section, a signature is generated using Python and verified using Solidity.
```bash
cd python-ref
make install
```
The public and private keys are generated using Python:
```bash
# generate public and private keys
./sign_cli.py genkeys --version='falcon' # --seed=0 
```
This command prints the public key in Solidity format:
```solidity
// Solidity public key:
// forgefmt: disable-next-line
uint[512] memory tmp_pk = [uint(7558), 462,7796,8887,3563,9934,5945,7574,1475,6477,8554,8550,742,11465,5529,6636,3634,4583,4564,5008,429,6295,11401,10190,12003,8391,10652,11155,8189,4982,3540,8875,7413,1184,2771,3870,6723,5521,3798,6503,883,10697,3125,11267,5609,10219,3567,6746,2503,1243,6605,2143,8791,10294,8221,3006,9030,10338,8281,11199,1509,411,1764,2443,10629,7499,3095,5843,9793,1649,11516,2086,6295,10722,4500,10607,6474,12240,4633,7931,10363,11461,11813,8323,7023,2080,6077,7377,1108,12095,8472,5736,64,11691,427,5949,6818,1493,11897,5879,4091,10486,6991,5212,2489,5311,4789,3336,11064,1881,8143,9472,10708,6158,11751,1811,8864,10343,3526,2704,1943,1653,4702,12066,7597,5638,7668,7319,10867,10470,8122,6765,10587,9113,4554,9143,11156,7159,11660,10238,4340,2151,2641,11875,5557,9704,1030,7156,7036,7414,10547,5199,11486,1259,10270,3187,3949,4451,3938,4138,8448,6020,10294,2673,7541,922,1720,8726,3556,6213,11111,72,9807,7654,447,6991,12238,10904,2158,3498,6381,1643,6502,1845,8416,1464,1256,8223,5977,5548,310,11709,11967,4257,734,5248,4977,5175,10280,6096,6443,8616,10818,5039,7108,535,1315,6896,2769,11351,9879,1628,8185,2020,9867,6290,843,3090,9289,3065,11672,7719,5184,7322,2221,4133,8787,6681,1286,5853,795,4016,10308,572,3006,3630,9094,10126,4442,3114,6924,3196,10604,8636,7798,469,7543,10150,400,11855,11468,4083,11594,12027,4351,6309,5839,7641,8839,8197,6311,3063,8970,4505,460,6696,10018,168,2518,12163,7382,3167,2350,10636,11595,6563,3972,5694,9465,3347,768,9478,6976,2200,11306,2431,1016,3624,7062,11810,10640,11787,10943,5989,3000,5267,11008,6320,794,1531,4774,7023,4553,1606,7220,9645,5764,3702,4177,5786,2068,4423,141,6459,1457,1466,907,10305,6310,12209,6997,6946,10971,8278,10321,6765,9042,447,10818,7172,11704,7850,3595,3415,6023,2000,3315,9532,7540,7277,6003,6824,5687,247,303,2426,7432,8449,3189,273,1913,2635,540,972,9895,1048,11879,7098,11735,11818,10808,5550,4001,7117,11227,1380,1401,2439,4325,3542,10248,1389,3221,1830,9595,10894,2851,5580,5904,6198,10383,7311,6182,8620,8656,6013,1180,9634,12002,9933,1095,4316,9515,3694,9290,4252,10764,12151,2508,4551,10576,10310,1721,8746,9419,8448,1163,559,6775,2553,770,7180,4087,10082,2049,11149,363,11377,5951,9288,7293,11303,11138,1468,2354,556,9334,10709,7245,7524,4657,8951,9175,1166,11231,6104,2281,5636,9281,8099,2023,9954,5389,2354,9806,9181,10526,10205,2009,7828,6098,2707,200,9784,8282,2608,8812,11089,9223,1415,4242,8590,4384,3455,11786,8881,9702,8275,3707,11502,5752,163,11550,5005,526,11527,4525,6914,3325,11755,7217,1161,4622,1352,188,3439,6916,10640,4437,7260,10089,2451,6272,10578,577,9793,10605,7750,5380,9160,3828,9984,6416,1335,8342,7927,7421,4859,2537,5852,8872,1073];
```
The signature is computed from the private key (stored in `private_key.pem`):
```bash
# generate a signature for the message "This is a demo"
./sign_cli.py sign --privkey='private_key.pem' --message="This is a demo" --version='falcon' # --seed=0
```
This commands prints the signature in the Solidity format:
```solidity
// Solidity raw signature:
// s2
// forgefmt: disable-next-line
uint[512] memory s2 = [uint(12109), 141, 12150, 12168, 89, 12213, 12150, 28, 109, 99, 12087, 29, 153, 247, 12204, 172, 12206, 23, 45, 12254, 123, 142, 12228, 12043, 94, 12215, 1, 0, 12029, 408, 11899, 12134, 11997, 12146, 47, 99, 28, 10, 12113, 150, 11, 12051, 106, 153, 12226, 12201, 12084, 149, 12256, 12226, 136, 12084, 12138, 12183, 12276, 12245, 172, 1, 13, 275, 12207, 12023, 12119, 12268, 12269, 43, 12092, 12144, 12114, 54, 12285, 12038, 12129, 12190, 111, 54, 11976, 72, 191, 151, 12140, 11910, 263, 12109, 12125, 11902, 12288, 132, 12257, 12273, 77, 12266, 57, 12276, 153, 24, 269, 37, 69, 191, 12060, 181, 12162, 12145, 251, 12075, 12193, 12232, 112, 12138, 236, 12128, 11946, 12, 12254, 78, 45, 12212, 57, 12110, 12071, 12266, 12282, 35, 12120, 12089, 3, 52, 12273, 50, 11920, 228, 12165, 304, 12145, 12, 67, 88, 108, 114, 14, 12206, 12140, 15, 462, 183, 12093, 368, 12164, 12022, 56, 268, 12190, 12209, 12228, 12227, 353, 12020, 0, 143, 12043, 63, 12286, 9, 11973, 12144, 38, 17, 12113, 12070, 11915, 12033, 98, 176, 12267, 12015, 11941, 12233, 12094, 24, 12122, 12186, 12195, 230, 12070, 146, 12223, 11, 12252, 81, 12216, 117, 177, 11991, 12270, 64, 12103, 11994, 12151, 12090, 12242, 168, 34, 77, 12068, 76, 8, 12176, 11987, 12245, 12241, 163, 65, 12101, 107, 12228, 12136, 264, 12070, 357, 23, 46, 57, 20, 12223, 12272, 16, 151, 84, 12070, 221, 105, 12113, 11924, 12227, 12213, 12080, 23, 12223, 12269, 12287, 269, 72, 438, 12020, 12086, 71, 254, 12121, 4, 254, 144, 12256, 12064, 12091, 24, 198, 9, 98, 12064, 12184, 82, 12223, 55, 12133, 12254, 47, 12166, 12121, 12152, 12027, 42, 21, 12100, 12257, 19, 12192, 206, 12199, 12154, 24, 12207, 11970, 202, 300, 58, 11896, 12013, 12236, 49, 342, 12191, 12032, 55, 12200, 201, 12211, 12263, 22, 11998, 12281, 12160, 12259, 12203, 80, 90, 72, 12211, 336, 76, 211, 41, 12234, 12216, 150, 54, 19, 102, 12054, 334, 12208, 241, 28, 12223, 12145, 12124, 0, 12206, 179, 1, 12178, 223, 12100, 34, 221, 12175, 12212, 34, 12131, 166, 4, 274, 12206, 12143, 12285, 47, 25, 12240, 361, 187, 12228, 56, 12271, 12204, 12193, 153, 12226, 12262, 213, 112, 126, 61, 12091, 152, 12190, 12219, 12202, 447, 12269, 12087, 260, 12150, 11909, 12226, 12256, 314, 92, 207, 11, 12278, 517, 12277, 87, 130, 61, 93, 125, 11884, 12227, 89, 12206, 116, 64, 221, 12168, 68, 266, 128, 12138, 263, 12274, 2, 12165, 62, 130, 18, 154, 12132, 50, 12167, 12035, 12069, 214, 12076, 320, 12175, 127, 12055, 208, 12133, 12046, 12207, 0, 12278, 12081, 12148, 132, 12238, 12119, 61, 139, 12286, 12240, 192, 12103, 27, 77, 184, 12148, 3, 12062, 12207, 12176, 46, 12254, 12152, 44, 204, 281, 42, 12131, 12124, 12076, 127, 12190, 37, 9, 3, 42, 12218, 12, 12180, 11860, 12265, 12161, 12146, 12244, 34, 12072, 183, 12271, 12158, 11978, 196, 12174, 184, 79, 186, 167, 12091, 112, 354, 11958, 12241, 55, 12275, 12059, 11923, 12203, 28, 25, 12233, 12156, 75, 12266, 250, 12267, 31, 3, 154, 12207, 109, 177, 202, 12191, 12036, 37, 12110, 12167, 12057, 134, 11977];

sig.salt = "\x35\x00\x31\x8f\x75\xad\x20\xf0\xaa\x20\x62\xba\x1c\x34\x8a\xfe\xaa\x49\x23\x87\xa4\x63\xeb\x8c\x28\xaf\x77\x9d\x6a\x3e\xa6\x96\xeb\xb9\x66\x0c\xcf\xf5\x06\x2d"; 
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
