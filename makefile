DIRSIGNER = 'python-ref'
PYTHON=python-ref/myenv/bin/python
CORES := $(shell grep -c ^processor /proc/cpuinfo)

# INSTALL

install: install_signer install_verifier

install_signer:
	make -C $(DIRSIGNER) install

install_verifier:
	foundryup
	forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit

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
	forge test -j$(CORES) -vv

test_onchain:
	# Generate public and private keys, sign a message, and verify it on-chain.
	$(PYTHON) python-ref/sign_cli.py genkeys --version='falcon'
	$(PYTHON) python-ref/sign_cli.py sign --privkey='private_key.pem' --data=546869732069732061207472616e73616374696f6e
	$(PYTHON) python-ref/sign_cli.py verifyonchain --pubkey='public_key.pem' --data=546869732069732061207472616e73616374696f6e --signature='sig' --contractaddress='0x5dc45800383d30c2c4c8f7e948090b38b22025f9' --rpc='https://ethereum-holesky-rpc.publicnode.com'
