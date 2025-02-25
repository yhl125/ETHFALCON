# falcon.py

This repository implements the signature scheme Falcon (https://falcon-sign.info/).
Falcon stands for **FA**st Fourier **L**attice-based **CO**mpact signatures over **N**TRU

## Content

This repository contains the following files (roughly in order of dependency):

1. [`common.py`](common.py) contains shared functions and constants
1. [`rng.py`](rng.py) implements a ChaCha20-based PRNG, useful for KATs (standalone)
1. [`samplerz.py`](samplerz.py) implements a Gaussian sampler over the integers (standalone)
1. [`fft_constants.py`](fft_constants.py) contains precomputed constants used in the FFT
1. [`fft.py`](fft.py) implements the FFT over R[x] / (x<sup>n</sup> + 1)
1. [`ntrugen.py`](ntrugen.py) generate polynomials f,g,F,G in Z[x] / (x<sup>n</sup> + 1) such that f G - g F = q
1. [`ffsampling.py`](ffsampling.py) implements the fast Fourier sampling algorithm
1. [`falcon.py`](falcon.py) implements Falcon
1. [`test.py`](test.py) implements tests to check that everything is properly implemented

## Interface
We provide an interface for key generation, signature and verification.

###### Key generation
```
./sign_cli.py genkeys --version='falcon' # or falconrec or epervier
```
It creates two files `private_key.pem` and `public_key.pem` storing the private and public keys.

###### Signature
```
./sign_cli.py sign --message="Example of message" --privkey=private_key.pem
```
It signs a message using a private key, and outputs the signature in hexadecimal format.

###### Verification
```
./sign_cli.py verify --message="Example of message" --pubkey=public_key.pem --signature="394...000"
```
It outputs the validity of the signature with respect to a message and a public key given as input. The signature needs to be provided as a (large) string.


## Profiling

I included a makefile target to performing profiling on the code. If you type `make profile` on a Linux machine, you should obtain something along these lines:

![kcachegrind](https://tprest.github.io/images/kcachegrind_falcon.png)

Make sure you have `pyprof2calltree` and `kcachegrind` installed on your machine, or it will not work.


## Authors

* **Thomas Prest** (thomas.prest@ens.fr) original author of Falcon implementation
* **Renaud Dubois** author of the modifications for ZKNox project.
* **Simon Masson** author of the modifications for ZKNox project.


## Disclaimer
This is an experimental code. The reference code of Falcon is on https://falcon-sign.info/. It is not to be considered secure or suitable for production. 

## License

MIT



## Tests

Tests of key generation, signing and verification can be done in iterative and recursive NTT. The HashToPoint can be set with the SHAKE256, KeccaXOF (implemented in Tetration), or KeccakPRNG (a PRNG based on Keccak).
```
make test
```
This runs the original tests, and additional tests made in `test_xxx.py`.

## (new) Benchmarks

<table>
  <tr>
    <th rowspan="2">n</th>
    <th colspan="2">Key generation</th>
    <th colspan="2">Signature</th>
    <th colspan="4">Verification</th>
  </tr>
  <tr>
    <td>NTT iterative</td>
    <td>NTT recursive</td>
    <td>SHAKE256</td>
    <td>KeccaXOF</td>
    <td>NTT iterative</td>
    <td>NTT recursive</td>
    <td>SHAKE256</td>
    <td>KeccaXOF</td>
  </tr>
  <tr>
    <td>64</td>
    <td>180 ms</td>
    <td>96 ms</td>
    <td>2.4 ms</td>
    <td>2.4 ms</td>
    <td>0.3 ms</td>
    <td>0.6 ms</td>
    <td>0.3 ms</td>
    <td>0.4 ms</td>
  </tr>
  <tr>
    <td>128</td>
    <td>825 ms</td>
    <td>1033 ms</td>
    <td>4.7 ms</td>
    <td>4.7 ms</td>
    <td>0.6 ms</td>
    <td>1.4 ms</td>
    <td>0.6 ms</td>
    <td>0.7 ms</td>
  </tr>
  <tr>
    <td>256</td>
    <td>1051 ms</td>
    <td>1530 ms</td>
    <td>9.7 ms</td>
    <td>9.4 ms</td>
    <td>1.3 ms</td>
    <td>3.0 ms</td>
    <td>1.3 ms</td>
    <td>1.3 ms</td>
  </tr>
  <tr>
    <td>512</td>
    <td>2273 ms</td>
    <td>1755 ms</td>
    <td>19.2 ms</td>
    <td>19.0 ms</td>
    <td>3.0 ms</td>
    <td>6.6 ms</td>
    <td>3.0 ms</td>
    <td>3.0 ms</td>
  </tr>
  <tr>
    <td>1024</td>
    <td>10256 ms</td>
    <td>13652 ms</td>
    <td>39.3 ms</td>
    <td>39.2 ms</td>
    <td>6.4 ms</td>
    <td>14.2 ms</td>
    <td>6.4 ms</td>
    <td>6.2 ms</td>
  </tr>
</table>
