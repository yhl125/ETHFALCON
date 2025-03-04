
# EXAMPLE OF USE

**This is an experimental work, not audited: DO NOT USE IN PRODUCTION, LOSS OF FUND WILL INCUR**

A signature is generated using Python and verified using Solidity following those steps.
```bash
cd python-ref
make install
```
The public and private keys are generated using Python:
```bash
# generate public and private keys
./sign_cli.py genkeys --version='falcon'
```
The signature is computed from the private key (stored in `private_key.pem`):
```bash
# generate a signature for the message "This is a demo"
./sign_cli.py sign --privkey='private_key.pem' --message="This is a demo" --version='falcon' # --seed=0
```
The signature can be verified on chain:
```bash
./sign_cli.py verifyonchain --pubkey='public_key.pem' --message="This is a demo" --signature='sig' --contractaddress='0xD2d8e3a5bCf8E177A627698176bC9a99E03D358D' --rpc='https://ethereum-holesky-rpc.publicnode.com'
```
This should output:
```
0x0000000000000000000000000000000000000000000000000000000000000001
```