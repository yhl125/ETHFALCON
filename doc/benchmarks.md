
### Solidity


| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork, recursive NTT | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form, recursive NTT | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| OK|




### Yul

Upon confirmation of the optimal algorithm for NTT, its critical parts have been implemented in Yul, benefiting from the extcodecopy trick described in 3.3, stack optimization, and variable control. The function verifyNIST is compliant to NIST signatures after decompression. As SHAKE is $70\%$ of computations, a EVM equivalent is proposed (using keccak).



| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|---------------------|
| ZKNOX_ethfalcon.verifyNIST       | ZKNOX_NTT      | 7M | :white_check_mark:|
| ZKNOX_ethfalcon.verify       | ZKNOX_NTT      | 1.9 M | :white_check_mark:|

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
