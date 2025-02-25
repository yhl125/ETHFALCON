#!myenv/bin/python
import argparse
import ast
from falcon import PublicKey, SecretKey
from falcon_epervier import EpervierPublicKey, EpervierSecretKey
from falcon_recovery import RecoveryModePublicKey, RecoveryModeSecretKey


def generate_keys(n, version):
    if version == 'falcon':
        sk = SecretKey(n)
        pk = PublicKey(n, sk.h)
    elif version == 'falconrec':
        sk = RecoveryModeSecretKey(n)
        pk = RecoveryModePublicKey(n, sk.h)
    elif version == 'epervier':
        sk = EpervierSecretKey(n)
        pk = EpervierPublicKey(n, sk.h)
    else:
        print("This version does not exist.")
        return
    return sk, pk


def save_pk(pk, filename):
    with open(filename, "w") as f:
        f.write("# public key\n")
        f.write("n = {}\n".format(pk.n))
        f.write("h = {}\n".format(pk.h))


def save_sk(sk, filename):
    with open(filename, "w") as f:
        f.write("# private key\n")
        f.write("n = {}\n".format(sk.n))
        f.write("f = {}\n".format(sk.f))
        f.write("g = {}\n".format(sk.g))
        f.write("F = {}\n".format(sk.F))
        f.write("G = {}\n".format(sk.G))


def load_pk(filename):
    with open(filename, "r") as f:
        data = f.read()
    variables = dict(line.split("=")
                     # first line is a comment
                     for line in data.splitlines()[1:])
    n = int(variables["n "])
    pk = ast.literal_eval(variables["h "])
    return PublicKey(n, pk)


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
    return SecretKey(n, polys=[f, g, F, G])


def verify_signature(pk, message, signature):
    sig = bytes.fromhex(signature)
    return pk.verify(message.encode(), sig)


def cli():
    parser = argparse.ArgumentParser(description="CLI for Falcon Signature")
    parser.add_argument("action", choices=[
                        "genkeys", "sign", "verify"], help="Action to perform")
    parser.add_argument("--version", type=str,
                        help="Version to use (falcon or falconrec)")
    parser.add_argument("--message", type=str,
                        help="Message to sign or verify")
    parser.add_argument("--privkey", type=str,
                        help="Private key file for signing")
    parser.add_argument("--pubkey", type=str,
                        help="Public key file for verification")
    parser.add_argument("--signature", type=str, help="Signature to verify")

    args = parser.parse_args()

    if args.action == "genkeys":
        if not args.version:
            print("Error: Provide --version")
            return
        # TODO make it parameterizable
        n = 512
        priv, pub = generate_keys(n, args.version)
        save_pk(pub, "public_key.pem")
        save_sk(priv, "private_key.pem")
        print("Keys generated and saved.")

    elif args.action == "sign":
        if not args.message or not args.privkey:
            print("Error: Provide --message and --privkey")
            return
        sk = load_sk(args.privkey)
        sig = sk.sign(args.message.encode())
        print(f"Signature: {sig.hex()}")

    elif args.action == "verify":
        if not args.message or not args.pubkey or not args.signature:
            print("Error: Provide --message, --pubkey and --signature")
            return
        pk = load_pk(args.pubkey)
        if verify_signature(pk, args.message, args.signature):
            print("Signature is valid.")
        else:
            print("Invalid signature.")


if __name__ == "__main__":
    cli()
