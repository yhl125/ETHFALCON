# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 

The repository implements several tweaked version of FALCON, optimized for different constraints.


<table>
  <tr>
    <th>Algorithm</th>
    <th>Source</th>
    <th>Description</th>
  </tr>
  <td>FALCON</td>
  <td>NIST</td>
  <td>The original FALCON NIST submission</td>
  </tr>
  <td>FALCON-SOLIDITY</td>
  <td>Tetration </td>
  <td>An EVM Friendly version of FALCON using keccak instead of SHAKE for XOF</td>
  </tr>
  <td>NOXFALCON</td>
  <td>ZKNOX </td>
  <td>An EVM Friendly version of FALCON using composition of ntt and keccak instead of SHAKE for XOF</td>
  </tr>

</table>   



## SOLIDITY 

### ETHFALCON 

For now, the solidity repo is a fork from the 
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo.
It is important to notice that the 
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo is EVM friendly and use a FALCON equivalent implementation using keccak instead of SHAKE.
It is thus not compliant with [FALCON](https://falcon-sign.info/falcon.pdf) NIST instanciation.
While not degrading the performances it is not compatible with the original specification.

The performances improvment brought by ZKNOX come from :
- some generic solidity gas cost optimizations (replacing mul by shifts, etc.)
- the replacement of a recursive NTT, by a NWC (Negative Wrap Convolution) specialized one as specified in EIP-NTT following [LN16]. This NTT is twice faster and doesn't need to store a table of $q$ elements
- the precomputation of the NTT from of the public key to avoid repetitive identical computations for each iteration.

The following optimizations are still WIP:
- Use Yul in critical sections
- Use memory access optimizations (extcodecopy trick)


### FALCON WITH RECOVERY
#### Description
This section described an optimized version of the falcon with recovery algorithm. 

The original Falcon with recovery as described section 3.12 of [FALCON](https://falcon-sign.info/falcon.pdf) is:
- The public key becomes $pk=H(h)$ for some collision-resistant hash function $H$;
- The signature becomes $(s_1, s_2, r)$ 
- The verifier accepts the signatures if and only if:
- $(s_1, s_2)$ is short;
- $pk=H(s_2^{-1}(HashToPoint(r\mid\mid m,q,n))-s_1)$


As for our precomputed public key ntt form, some of the verification work is delegated to the
front. The Falcon recovery requires a polynomial division to recover the public key value. We use a classical trick in ZK implementations by providing this as an extra value (a hint) in the calldata. The front also process the ntt transformation of $s_2^{-1}$.
The verification then becomes:
- The public key becomes $pk=H(h)$ for some collision-resistant hash function $H$;
- The signature becomes $(s_1, s_2, r, ntt(s_2^{-1}))$ 
- The verifier accepts the signatures if and only if:
    - $(s_1, s_2)$ is short;
    - $ntt(s_2)*ntt(s_2^{-1})==ntt(1)$;
    - $pk==H(s_2^{-1}(HashToPoint(r\mid\mid m,q,n))-s_1)$.

Notes:

- ntt(1) is the constant equal to a one at each position (trivial equality test)
- defining HashToPoint as InvNTT(PRNG_Keccak(x)) avoid a NTT transform, the computation of $s_2^{-1}(HashToPoint(r\mid\mid m,q,n))$ only requires then a single InvNTT
- only two NTT transformations are required, leading to a verification time equivalent to the falcon without recovery
- the NTT used here is the NWC defined in NTT-EIP
- PRNG_Keccak is a construction that generates the desired output only using keccak (EVM friendly) 

Discussion:
- it would be possible to totally avoid to use Inverse NTT by defining H as H=ntt(keccak(c), this would reduce the surface of hardware implementation.

#### Description


## BENCHMARKS


### SOLIDITY

| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| OK|
| falcon.recover         | Use of hinted $s_2^{-1}$, custom iterative NTT | 8.3 M (Theoretical) | TBC|


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


## REFERENCES
- [[FALCON]](https://falcon-sign.info/falcon.pdf) Falcon: Fast-Fourier Lattice-based
Compact Signatures over NTRU
- [[NTT-EIP]]() NTT-EIP as a building block for FALCON, DILITHIUM and Stark verifiers 
- [[Tetration]](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) Falcon solidity.
