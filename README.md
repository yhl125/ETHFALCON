#ETHFALCON

ETHFALCON gather experimentations around FALCON adaptations for the ETHEREUM ecosystem. [Falcon signature scheme](https://falcon-sign.info/) is a post-quantum digital signature algorithm. 


## SOLIDITY 

For now, the solidity repo is a fork from the https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol repo.


### BENCHMARKS
| Function                   | Description               | gas cost | 
|------------------------|---------------------|---------------------|
| falcon.verify       | original gas cost from [falcon-solidity](https://github.com/Tetration-Lab/falcon-solidity/blob/main/src/Falcon.sol)         | 24M
| falcon.verify      | ZKNOX fork | 20.8 M
| falcon.verify_opt         | Use of precomputed NTT public key form | 14.6 M