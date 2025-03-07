
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
./sign_cli.py sign --privkey='private_key.pem' --message="This is a demo" --version='falcon'
```
The signature can be verified on chain:
```bash
./sign_cli.py verifyonchain --pubkey='public_key.pem' --message="This is a demo" --signature='sig' --contractaddress='0xD2d8e3a5bCf8E177A627698176bC9a99E03D358D' --rpc='https://ethereum-holesky-rpc.publicnode.com'
```
This should output:
```
0x0000000000000000000000000000000000000000000000000000000000000001
```

___
___
## Transaction output

For computing a transaction, we need to provide:
* A `nonce`, unique identifier as a `uint256` given in hex,
* The destinary address `to`, a `uint160` given in hex,
* The transaction `data` to be signed, given as `bytes`,
* The value ??? as a `uint256` given in hex,

For the signature, we also need to provide:
* The private key file,
* The version of the scheme (it works only for `falcon` for now),
* The public key (TODO it should be computed from the private key)
```bash
./sign_cli.py sign_tx --data='This is a transaction' --privkey=private_key.pem --version='falcon' --nonce=0123456789 --to=0xadd4e55 --value=ffff --pubkey=public_key.pem
```
This outputs the useful data for the transaction:
* The hash for the transaction`TX_HASH`: `Keccak256(nonce|to|data|value)`,
* The signature `S2` in compact form,
* The `SALT` value,
* The public key `PK` in NTT in compact form.
