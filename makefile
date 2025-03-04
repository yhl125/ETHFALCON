DIRSIGNER = 'python-ref'
PYTHON=python-ref/myenv/bin/python

# INSTALL

install: install_signer install_verifier

install_signer:
	make -C $(DIRSIGNER) install

install_verifier:
	foundryup
	forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# GENERATION OF TEST VECTORS

gen_test_vectors:
	make -C $(DIRSIGNER) generate_test_vectors


# TESTS

test: test_signer test_verifier test_onchain

test_slow: test_signer test_verifier_slow test_onchain

test_signer:
	make -C $(DIRSIGNER) test

test_verifier:
	FOUNDRY_PROFILE=lite forge test -vv

test_verifier_slow:
	forge test -vv

test_onchain:
	# Generate public and private keys, sign a message, and verify it on-chain.
	$(PYTHON) python-ref/sign_cli.py genkeys --version='falcon'
	$(PYTHON) python-ref/sign_cli.py sign --privkey='private_key.pem' --message='This is a demo' --version='falcon'
	$(PYTHON) python-ref/sign_cli.py verifyonchain --pubkey='public_key.pem' --message='This is a demo' --signature='sig' --contractaddress='0xD2d8e3a5bCf8E177A627698176bC9a99E03D358D' --rpc='https://ethereum-holesky-rpc.publicnode.com'
