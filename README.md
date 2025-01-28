#ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 


## SOLIDITY 

For now, the solidity repo is a fork from the https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol repo.


### BENCHMARKS
| Function                   | Description               | gas cost | Tests Status |
|------------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M | OK|
| falcon.verify      | ZKNOX fork | 20.8 M| OK|
| falcon.verify_opt         | Use of precomputed NTT public key form | 14.6 M| OK|
| falcon.verify_iterative         | Use of precomputed NTT public key form, custom iterative NTT | 8.3 M| KO|



## ACKNOWLEDGEMENTS

The NTT used as reference has been inspired from https://github.com/acmert/ntt-based-polmul/tree/master exhaustive implementations.
