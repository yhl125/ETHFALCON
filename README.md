# ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 




## SPECIFICATION

The repo implements several versions of FALCON, some are tunned to EVM constraints, find specification [here](./doc/specification.md) 


## INSTALLATION

**This is an experimental work, not audited: DO NOT USE IN PRODUCTION, LOSS OF FUND WILL OCCUR**

The repo contains a solidity verifier and a python signer. 

### Solidity

1. Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Clone the repository:

```bash
git clone https://github.com/ZKNoxHQ/ETHFALCON.git
```

3. Install dependencies:

```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
```

4. Build the project (slow):

```bash
forge build
```

(fast, more gas)
```bash
 FOUNDRY_PROFILE=lite forge build 
```

5. Run tests:

```bash
forge test -vv
```
### Python

Go to python-ref then

1. Install:

```bash
make install
```
1. Run tests:

```bash
make tests
```

## BENCHMARKS

Benchmarks for both solidity code and python are available [here](./doc/benchmarks.md)

Current fastest implementation is 1.9M gas.

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
