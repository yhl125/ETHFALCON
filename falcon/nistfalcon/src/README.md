# FALCON AND EPERVIER

## Description
This directory is based on the FALCON reference implementation submitted to NIST. We follow the implementation of the public-key recovery that was located in `Extra/` directory. We obtain two new versions of FALCON:
* One version follows the NIST with a 16-bit encoding of the public key and the signature. In FALCON, a specific encoding is used from the fact that integers are always less than $q$ and fit in 14 bits. We decide here to encode with 16 bits, as it fits better with the architecture in Solidity, where a "machine word" is 256-bit long.
* One version is a public-key recovery version where `pk` is moved to the NTT domain. The public key is finally $H(NTT(h))$ where $h$ is the public key in falcon, and $H$ is a 256-bit output hash function such as Keccak. Note that we did not implement the final hash $H$ here. Thus, the verifier recomputes completely $NTT(h)$ and a final check would be required in practice (in solidity).
  
## How to use 
We provide a way to create _KAT vectors_ following NIST standards. First, run:
```bash
make
```
* In order to create the KAT vectors for the NIST (from the initial repository):
    ```bash
    ./build/kat512int
    ```
    These vectors can be used in [this file](../../../test/ZKNOX_falconKATS.t.sol) in order to test the solidity verification algorithm, but this requires a `decompression_KAT()` first.
* In order to create the same KAT vectors but with the 16-bit encoding for the public key and the signature:
    ```bash
    ./build/zknox_kat512int
    ```
    Using these vectors, it is easier to manipulate in solidity (see [this same file](../../../test/ZKNOX_falconKATS.t.sol) below).
* In order to create KAT vectors for EPERVIER, the public-key recovery version of FALCON (with 16-bit encoding):
    ```bash
    ./build/zknox_kat512int_epervier
    ```
    **WIP: using it in solidity.**

## Solidity binding
The three commands should create the following files:
```bash
PQCsignKAT_falcon512int.req
PQCsignKAT_falcon512int.rsp
zknox_PQCsign_epervierKAT_falcon512int.req
zknox_PQCsign_epervierKAT_falcon512int.rsp
zknox_PQCsignKAT_falcon512int.req
zknox_PQCsignKAT_falcon512int.rsp
```
The test vectors can be used in Solidity as explained above. See the examples in [this file](../../../test/ZKNOX_falconKATS.t.sol).