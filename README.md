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


## Installation

forge install OpenZeppelin/openzeppelin-contracts


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
The signature is computed from the private key (stored in `private_key.pem`):
```bash
# generate a signature for the message "This is a demo"
./sign_cli.py sign --privkey='private_key.pem' --message="This is a demo" --version='falcon' # --seed=0
```
The signature can be verified on chain:
```bash
./sign_cli.py verifyonchain --pubkey='public_key.pem' --message="This is a demo" --signature='sig' --contract_address='0xD2d8e3a5bCf8E177A627698176bC9a99E03D358D' --rpc='https://ethereum-holesky-rpc.publicnode.com'
```
This should output:
```
Signature is valid.
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
