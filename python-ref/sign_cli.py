#!myenv/bin/python
import argparse
import ast
import subprocess
from common import falcon_compact, q
from encoding import decompress
from falcon import HEAD_LEN, SALT_LEN, PublicKey, SecretKey
from falcon_epervier import EpervierPublicKey, EpervierSecretKey
from falcon_recovery import RecoveryModePublicKey, RecoveryModeSecretKey
from polyntt.poly import Poly
from shake import SHAKE
from Crypto.Hash import keccak
from eth_abi import encode
from eth_abi.packed import encode_packed


import random


def generate_keys(n, version):
    # private key
    if version == 'falcon':
        SK = SecretKey
    elif version == 'falconrec':
        SK = RecoveryModeSecretKey
    elif version == 'epervier':
        SK = EpervierSecretKey
    else:
        print("This version does not exist.")
        return

    sk = SK(n)

    if version == 'falcon':
        pk = PublicKey(n, sk.h)
    elif version == 'falconrec':
        pk = RecoveryModePublicKey(n, sk.pk)
    elif version == 'epervier':
        pk = EpervierPublicKey(n, sk.pk)

    return sk, pk


def save_pk(pk, filename, version):
    with open(filename, "w") as f:
        f.write("# public key\n")
        f.write("n = {}\n".format(pk.n))
        f.write("pk = {}\n".format(pk.pk))
        f.write("version = {}\n".format(version))


def save_sk(sk, filename, version):
    with open(filename, "w") as f:
        f.write("# private key\n")
        f.write("n = {}\n".format(sk.n))
        f.write("f = {}\n".format(sk.f))
        f.write("g = {}\n".format(sk.g))
        f.write("F = {}\n".format(sk.F))
        f.write("G = {}\n".format(sk.G))
        f.write("version = {}\n".format(version))


def save_signature(sig, filename):
    with open(filename, "w") as f:
        f.write(sig.hex())


def load_pk(filename):
    with open(filename, "r") as f:
        data = f.read()
    variables = dict(line.split("=")
                     # first line is a comment
                     for line in data.splitlines()[1:])
    n = int(variables["n "])
    pk = ast.literal_eval(variables["pk "])
    version = variables["version "].lstrip()
    if version == 'falcon':
        return PublicKey(n, pk)
    elif version == 'falconrec':
        return RecoveryModePublicKey(n, pk)
    elif version == 'epervier':
        return EpervierPublicKey(n, pk)
    else:
        print("This version is not supported.")
        return


def load_sk(filename):
    with open(filename, "r") as f:
        data = f.read()
    variables = dict(line.split("=")
                     # first line is a comment
                     for line in data.splitlines()[1:])
    n = int(variables["n "])
    f = ast.literal_eval(variables["f "])
    g = ast.literal_eval(variables["g "])
    F = ast.literal_eval(variables["F "])
    G = ast.literal_eval(variables["G "])
    version = variables["version "].lstrip()
    if version == 'falcon':
        return SecretKey(n, polys=[f, g, F, G])
    elif version == 'falconrec':
        return RecoveryModeSecretKey(n, polys=[f, g, F, G])
    elif version == 'epervier':
        return EpervierSecretKey(n, polys=[f, g, F, G])
    else:
        print("This version is not supported.")
        return


def load_signature(filename):
    with open(filename, "r") as f:
        signature = f.read()
    return bytes.fromhex(signature)


def signature(sk, data, version):
    # De-randomization of urandom as RFC 6979 page 10-11.
    deterministic_bytes = SHAKE()
    # v = 0x00 32 times in the case of a hash function with output 256 bits.
    # WARNING: this is probably not secure as it is implemented.
    deterministic_bytes.update(bytes(
        [0x01]*32
    ))
    # separator
    deterministic_bytes.update(bytes([0x00]))
    # secret key encoded
    deterministic_bytes.update(b''.join(x.to_bytes(2, 'big') for x in sk.h))
    # data TODO consider h(M) instead here.
    # if H does not output 32 bytes, change V above.
    deterministic_bytes.update(data)

    sig = sk.sign(
        data,
        randombytes=deterministic_bytes.read
    )
    if version == 'falcon':
        enc_s = sig[HEAD_LEN + SALT_LEN:]
        s2 = decompress(enc_s, sk.sig_bytelen - HEAD_LEN - SALT_LEN, sk.n)
        s2 = [elt % q for elt in s2]
    elif version == 'falconrec':
        enc_s = sig[HEAD_LEN + SALT_LEN:-sk.n*3]
        s = decompress(enc_s, sk.sig_bytelen*2 - HEAD_LEN - SALT_LEN, sk.n*2)
        mid = len(s)//2
        s = [elt % q for elt in s]
        s1, s2 = s[:mid], s[mid:]
        s2_inv_ntt = Poly(s2, q).inverse().ntt()
    elif version == 'epervier':
        enc_s = sig[HEAD_LEN + SALT_LEN:-sk.n*3]
        s = decompress(enc_s, sk.sig_bytelen*2 - HEAD_LEN - SALT_LEN, sk.n*2)
        mid = len(s)//2
        s = [elt % q for elt in s]
        s1, s2 = s[:mid], s[mid:]
        s2_inv_ntt = Poly(s2, q).inverse().ntt()
        s2_inv_ntt_prod = 1
        for elt in s2_inv_ntt:
            s2_inv_ntt_prod = (s2_inv_ntt_prod * elt) % q
    else:
        print("This version is not implemented.")
        return
    return sig


def transaction_hash(nonce, to, data, value):
    keccak_ctx = keccak.new(digest_bytes=32)
    packed = encode(
        # seem that `to` is considered as uint256
        ["uint256", "uint160", "bytes", "uint256"],
        [nonce, to, data, value]
    )
    keccak_ctx.update(packed)
    return keccak_ctx.digest()


def print_signature_transaction(sig, pk, tx_hash):
    TX_HASH = "0x" + tx_hash.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s2 = decompress(enc_s, pk.sig_bytelen - HEAD_LEN - SALT_LEN, 512)
    s2 = [elt % q for elt in s2]
    s2_compact = falcon_compact(s2)
    S2 = str(s2_compact)
    pk_compact = falcon_compact(Poly(pk.pk, q).ntt())
    PK = str(pk_compact)
    print("TX_HASH = {}".format(TX_HASH))
    print("PK = {}".format(PK))
    print("S2 = {}".format(S2))
    print("SALT = {}".format(SALT))


def verify_signature(pk, data, sig):
    return pk.verify(data, sig)


def verify_signature_on_chain(pk, data, sig, contract_address, rpc):

    MSG = "0x" + data.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s2 = decompress(enc_s, pk.sig_bytelen - HEAD_LEN - SALT_LEN, 512)
    s2 = [elt % q for elt in s2]
    s2_compact = falcon_compact(s2)
    S2 = str(s2_compact)
    pk_compact = falcon_compact(Poly(pk.pk, q).ntt())
    PK = str(pk_compact)

    result = subprocess.run(
        "cast call {} \"verify(bytes,bytes,uint256[],uint256[])\" {} {} \"{}\" \"{}\" --rpc-url {}".format(
            contract_address,
            MSG,
            SALT,
            S2,
            PK,
            rpc
        ),
        shell=True,
        capture_output=True,
        text=True
    )
    assert result.stderr == ''
    print(result.stdout)


def verify_signature_on_chain_with_transaction(pk, data, sig, contract_address, rpc, private_key):

    MSG = "0x" + data.encode().hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s2 = decompress(enc_s, pk.sig_bytelen - HEAD_LEN - SALT_LEN, 512)
    s2 = [elt % q for elt in s2]
    s2_compact = falcon_compact(s2)
    S2 = str(s2_compact)
    pk_compact = falcon_compact(Poly(pk.pk, q).ntt())
    PK = str(pk_compact)

    result = subprocess.run(
        "cast send --private-key {} {} \"verify(bytes,bytes,uint256[],uint256[])\" {} {} \"{}\" \"{}\" --rpc-url {}".format(
            private_key,
            contract_address,
            MSG,
            SALT,
            S2,
            PK,
            rpc
        ),
        shell=True,
        capture_output=True,
        text=True
    )
    print(result.stderr)
    assert result.stderr == ''
    print(result.stdout)


def cli():
    parser = argparse.ArgumentParser(description="CLI for Falcon Signature")
    parser.add_argument("action", choices=[
                        "genkeys", "sign", "sign_tx", "verify", "verifyonchain", "verifyonchainsend"], help="Action to perform")
    parser.add_argument("--version", type=str,
                        help="Version to use (falcon or falconrec)")
    parser.add_argument("--nonce", type=str,
                        help="nonce in hexadecimal to sign the transaction")
    parser.add_argument("--to", type=str,
                        help="Destination in hexadecimal address for the transaction")
    parser.add_argument("--data", type=str,
                        help="Data to be signed in hexadecimal")
    parser.add_argument("--value", type=str,
                        help="Value in hexadecimal for the transaction")
    parser.add_argument("--privkey", type=str,
                        help="Private key file for signing")
    parser.add_argument("--pubkey", type=str,
                        help="Public key file for verification")
    parser.add_argument("--contractaddress", type=str,
                        help="Contract address for on-chain verification")
    parser.add_argument("--rpc", type=str,
                        help="RPC for on-chain verification")
    parser.add_argument("--privatekey", type=str,
                        help="Ethereum ECDSA private key for sending a transaction")
    parser.add_argument("--signature", type=str, help="Signature to verify")

    args = parser.parse_args()

    if args.action == "genkeys":
        if not args.version:
            print("Error: Provide --version")
            return
        # TODO make it parameterizable?
        n = 512
        priv, pub = generate_keys(n, args.version)
        save_pk(pub, "public_key.pem", args.version)
        save_sk(priv, "private_key.pem", args.version)
        print("Keys generated and saved.")

    elif args.action == "sign":
        if not args.data or not args.privkey or not args.version:
            print("Error: Provide --data, --privkey and --version")
            return
        sk = load_sk(args.privkey)
        sig = signature(sk, bytes.fromhex(args.data), args.version)
        save_signature(sig, 'sig')

    elif args.action == "sign_tx":
        if not args.data or not args.privkey or not args.version or not args.nonce or not args.to or not args.value:
            print(
                "Error: Provide --data, --privkey, --version, --nonce, --to and --value")
            return
        tx_hash = transaction_hash(
            int(args.nonce, 16),
            int(args.to, 16),
            bytes.fromhex(args.data),
            int(args.value, 16)
        )
        print(tx_hash)
        sk = load_sk(args.privkey)
        pk = PublicKey(512, sk.h)
        sig = signature(sk, tx_hash, args.version)
        assert (verify_signature(pk, tx_hash, sig))
        print_signature_transaction(sig, pk, tx_hash)

    elif args.action == "verify":
        if not args.data or not args.pubkey or not args.signature:
            print("Error: Provide --data, --pubkey and --signature")
            return
        pk = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        if verify_signature(pk, bytes.fromhex(args.data), sig):
            print("Signature is valid.")
        else:
            print("Invalid signature.")

    elif args.action == "verifyonchain":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress and --rpc")
            return
        pk = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        verify_signature_on_chain(
            pk, bytes.fromhex(args.data), sig, args.contractaddress, args.rpc)

    elif args.action == "verifyonchainsend":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress or not args.privatekey:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress, --rpc and --privatekey")
            return
        pk = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        verify_signature_on_chain_with_transaction(
            pk, bytes.fromhex(args.data), sig, args.contractaddress, args.rpc, args.privatekey)


if __name__ == "__main__":
    cli()
