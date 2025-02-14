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
  <td>EPERVIER</td>
  <td>ZKNOX </td>
  <td>An EVM Friendly version of FALCONREC  avoiding expensive operations </td>
  <td> WIP</td>
  </tr>

</table>   

The difference lies mainly in the definition of the inner expandable hash functions (XOF) required in $HashToPoint$ and $H$ (this latest only for recovery).

<table>
  <tr>
    <th>Algorithm</th>
    <th> XOF core function </th>
    <th> H </th>
  </tr>
  <td> FALCON </td>
  <td> SHAKE</td>
  <td> N/A </td>
  </tr>
  </tr>
    <td> FALCON-SOLIDITY </td>
    <td> Keccak </td>
    <td> N/A </td>
  </tr>
 </tr>
  <td> EPERVIER </td>
  <td> NTTINV, Keccak </td>
  <td> Keccak(NTT(x)) </td>
  </tr>


</table>     

### FALCON 


#### FALCON

FALCON refers to the original [specification](https://falcon-sign.info/falcon.pdf), as submitted to NIST.
The specification also includes a recovery version that will be refered as FALCONREC. While not present in standard available implementation, it is valuable in the context of ETHREUM to stick to the ecrecover specification.

#### RECOVERY VERSION 

The original Falcon with recovery as described section 3.12 of [FALCON](https://falcon-sign.info/falcon.pdf) is:
- The public key becomes $pk=H(h)$ for some collision-resistant hash function $H$;
- The signature becomes $(s_1, s_2, r)$ 
- The verifier accepts the signatures if and only if:
- $(s_1, s_2)$ is short;
- $pk=H(s_2^{-1}(HashToPoint_{SHAKE}(r\mid\mid m,q,n)-s_1))$




### FALCON-SOLIDITY : EVM-FRIENDLY

FALCON-SOLIDITY refers to the specification of
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo.
It is important to notice that the 
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo is EVM friendly and use a FALCON equivalent implementation using keccak instead of SHAKE.
It is thus not compliant with [FALCON](https://falcon-sign.info/falcon.pdf) NIST instanciation.
While assumingly not degrading the  security it is not compatible with the original specification.

#### Optimizations

The performances improvment brought by ZKNOX to this version comes from :
-  generic solidity gas cost optimizations (replacing mul by shifts, etc.)
- the replacement of a recursive NTT, by a NWC (Negative Wrap Convolution) specialized one as specified in EIP-NTT following [LN16]. This NTT is twice faster and doesn't need to store a table of $q$ elements
- the precomputation of the NTT from of the public key to avoid repetitive identical computations for each iteration.





#### Uncovered vulnerabilities on Tetration [v1.0](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)


| LABEL                   | Severity | Description               |  Impact |Fix | PR |
|------------------------|---------------------|---------------------|---------------------|---------------------|---------------------|
|CVETH-2025-080201| critical  | salt size is not checked in verification | forge | add salt size checking | TBD
|CVETH-2025-080202| medium | signature malleability on coefficient signs | malleability | force positive coefficients in s part | TBD
|CVETH-2025-080203| low | no domain separation of internal state input and output | XOF design infringment | modify FALCON-SOLIDITY XOF specification | TBD


### EPERVIER: a compact circuit EVM-FRIENDLY FALCON with recovery
#### Description

This section described an optimized version (for the circuit size) of the falcon with recovery algorithm. 

As for our precomputed public key ntt form, some of the verification work is delegated to the
front. The Falcon recovery requires a polynomial division to recover the public key value. We use a classical trick in ZK implementations by providing this as an extra value (a hint) in the calldata. The front also process the ntt transformation of $s_2^{-1}$. The verifier needs an extra check for then $s_2 \times s_2^{-1} == 1$ and the public key check becomes $pk==H(s_2^{-1}\times(HashToPoint(r\mid\mid m,q,n)-s_1))$.

This verification requires `2NTT + 1iNTT` for step 2, and `1NTT + 1iNTT` for step 3 ($NTT(s_2^{-1})$ being already computed). This can be reduced by computing $NTT(s_2^{-1})$ by the signer, and modifying $H$ and $HashToPoint$ in order to compute multiplication in the NTT domain. We denote Epervier this setting for the adaption of Recover Mode of Falcon.

**Epervier** is summarized as follows:
- Public key: $pk=H(ntt(h))$ for some collision-resistant hash function $H$;
- Signature: $σ = (s_1, s_2, r, ntt(s_2^{-1}))$ 
- The verifier accepts the signatures if and only if:
    - $(σ_1,σ_2)$ is short;
    - $ntt(σ_2)\cdot σ_4==ntt(1)$;
    - $pk==H(σ_4\cdot (ntt(HashToPoint(r\mid\mid m,q,n)-σ_1)))$.
<!-- - By picking HashToPoint=NTTINV(PRNG_{Keccak}(x)) and $H=keccak(NTT(x))$, the last line of the verification is equivalent to
   - $pk== keccak(ntt(s_2^{-1}).PRNG_{Keccak}(x)- ntt(s_1)) $
   - this selection only requires two NTT transforms and no inverse NTT. -->

Using this verification, we compute only **2NTT** (+ additional hashes and vectorized arithmetic) for the verification. We claim that the interest of EPERVIER goes beyond Ethereum ecosystem. For Hardware implementations, avoiding a NTTINV reduces the total required gates. Using a pipeline, it also enables to reuse the same NTT circuit inducing only latency of one stage of the implementation.



Remarks:
- ntt(1) is the constant equal to a one at each position (trivial equality test)
<!-- - defining HashToPoint as NTTINV(PRNG_Keccak(x)) avoid a NTT transform, the computation of $H(s_2^{-1}(HashToPoint(r\mid\mid m,q,n))-s_1)$ only requires then a single InvNTT -->
- only two NTT transformations are required, leading to a verification time equivalent to the falcon without recovery
- the NTT used here is the NWC defined in NTT-EIP
- PRNG_Keccak is a construction that generates the desired output only using keccak (EVM friendly) 
- Defining H as H=ntt(keccak(c) remove to use Inverse NTT, this reduces the surface of hardware implementation.


## BENCHMARKS


### SOLIDITY


| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| OK|
| falcon.recover         | Use of hinted $s_2^{-1}$, custom iterative NTT | 8.3 M (Theoretical) | TBC|

### YUL

Upon confirmation of the optimal algorithm for NTT, its critical parts have been implemented in Yul, benefiting from the extcodecopy trick described in 3.3, stack optimization, and variable control.


| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | ZKNOX_NTT      | 4.2M | OK|
| falcon.verify_opt       | ZKNOX_NTT with precomputations         | 3.6M | OK|


### PYTHON

NTT implementation are benchmarked against Tetration implementation. The implementation enables to select the XOF function and the algorithm to compute NTT (iterative or recursive).

<table>
  <tr>
    <th>n</th>
    <th>Falcon Verification (ZKNox)</th>
    <th>Falcon Verification (Tetration)</th>
  </tr>
    <td>64</td>
    <td>0.3 ms</td>
    <td>0.6 ms</td>
  </tr>
  <tr>
    <td>128</td>
    <td>0.6 ms</td>
    <td>1.4 ms</td>
  </tr>
  <tr>
    <td>256</td>
    <td>1.3 ms</td>
    <td>3.0 ms</td>
  </tr>
  <tr>
    <td>512</td>
    <td>3.0 ms</td>
    <td>6.6 ms</td>
  </tr>
  <tr>
    <td>1024</td>
    <td>6.4 ms</td>
    <td>14.2 ms</td>
  </tr>
</table> 


## CONCLUSION

This repo provides a highly optimized version of FALCON. Order of magnitudes were gained compared to other implementations. In our search, we also devise a way to implement falcon with recovery without requiring the inverse NTT transformation (only forward).
Despite those efforts, it doesn't seem plausible to reach operational (below 1M) verification cost. Nevertheless, the provided code allow Account Abtraction using 7702 or 4337 from today.
The architecture also demonstrates that providing NTT would allow an acceptable cost, and provide more genericity and agility in the PQ signature candidate of Ethereum. For this reason [NTT-EIP]() is submitted.

## REFERENCES
- [[EXTCODE COPY TRICK]](https://eprint.iacr.org/2023/939) section 
- [[FALCON]](https://falcon-sign.info/falcon.pdf) Falcon: Fast-Fourier Lattice-based
Compact Signatures over NTRU
- [[NTT-EIP]]() NTT-EIP as a building block for FALCON, DILITHIUM and Stark verifiers 
- [[Tetration]](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) Falcon solidity.
