# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 


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
- the replacement of a recursive NTT, by a NWC (Negative Wrap Convolution) specialized one as specified in EIP-NTT following [LN16].
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

Note that only one NTT transformation is required (and no inverse), leading to the fastest verification algorithm.

#### Description


## BENCHMARKS

| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| OK|
| falcon.recover         | Use of hinted $s_2^{-1}$, custom iterative NTT | TBD| TBD|



## REFERENCES
- [[FALCON]](https://falcon-sign.info/falcon.pdf) Falcon: Fast-Fourier Lattice-based
Compact Signatures over NTRU
- [[NTT-EIP]]() NTT-EIP as a building block for FALCON, DILITHIUM and Stark verifiers 
- [[Tetration]](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) Falcon solidity.
