# Geth recipee for falcon Minimal fork

This directory contains the minimal sources to have a forked geth including a Falcon Precompile.


- Compile ETHFALCON/falcon go bindings

 ```bash
make go
 ```

- Clone geth repository

```bash
git clone https://github.com/ethereum/go-ethereum.git
 ```

- Replace contracts.go by the forked version of this directory
```bash
mv contracts.go $YOURGETH/core/vm/contracts.go
 ```


- Provide falcon go module to geth
```bash
go clean -modcache
go get github.com/ZKNoxHQ/ETHFALCON/falcon@latest
 ```

- Compile geth
```bash
make geth
 ```


- Run geth in dev mode:
```bash
./build/bin/geth --http --http.api eth,net,web3 --http.addr 127.0.0.1 --http.port 8545 --dev
 ```


- Run example with cast:
```bash
cast call 0x0000000000000000000000000000000000000013 $INPUT --rpc-url http://localhost:8545
 ```
where INPUT is a valid input for the falcon verification procedure, 0x13 is the precompile value (subject to change with next forks).
