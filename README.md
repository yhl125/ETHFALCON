# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 


## SOLIDITY 

For now, the solidity repo is a fork from the 
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo.
It is important to notice that the 
[Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) repo is EVM friendly and use a FALCON equivalent implementation using keccak instead of SHAKE.
While not degrading the performances it is not compatible with the original specification.

The performances improvment brought by ZKNOX come from :
- some generic solidity gas cost optimizations (replacing mul by shifts, etc.)
- the replacement of a recursive NTT, by a NWC (Negative Wrap Convolution) specialized one as specified in EIP-NTT following [LN16].
- the precomputation of the NTT from of the public key to avoid repetitive identical computations for each iteration.

The following optimizations are still WIP:
- Use Yul in critical sections
- Use memory access optimizations (extcodecopy trick)

## BENCHMARKS

| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| KO|



## REFERENCES

- [NTT-EIP]() NTT-EIP as a building block for FALCON, DILITHIUM and Stark verifiers 
- [Tetration](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol) Falcon solidity.
