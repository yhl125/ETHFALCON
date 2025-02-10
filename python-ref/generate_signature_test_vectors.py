from falcon import HEAD_LEN, SALT_LEN, Params, decompress, SecretKey, PublicKey
from polyntt.poly import Poly
from common import q
from scripts.sign_KAT import sign_KAT
from keccaxof import KeccaXOF

file = open("../test/SignatureTestVectors.sol", 'w')
n = 512
sk = SecretKey(n)
pub = PublicKey(sk)

header = """
// code generated using pythonref/sig_to_solidity.py.
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Falcon} from "../src/ETHFalcon_Recursive.sol";

contract SignatureTestVectors is Test {
    int constant q = 12289;
    Falcon falcon;

    function setUp() public {
        falcon = new Falcon();
    }
"""
file.write(header)

for (i, message) in enumerate(["My name is Renaud", "My name is Simon", "My name is Nicolas", "We are ZKNox"]):
    sig = sk.sign(message.encode(), xof=KeccaXOF)
    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s1 = decompress(enc_s, sk.sig_bytelen - HEAD_LEN - SALT_LEN, sk.n)
    s1_inv = Poly(s1, q).inverse().coeffs
    h = sk.hash_to_point(salt, message.encode())
    h_ntt = Poly(h, q).ntt()
    # write to file
    # file = open("sig_{}.txt".format(i), 'w')
    # file.write("message = \"{}\"\n".format(message))
    # file.write("salt = {}\n".format(salt))
    # file.write("s1 = {}\n".format(s1))
    # file.write("s1_inv = {}\n".format(s1_inv))
    # file.write("h_ntt = {}\n".format(h_ntt))
    assert sk.verify(message.encode(), sig, xof=KeccaXOF)

    file.write("function testVector{}() public view {{\n".format(i))
    file.write("// public key\n")
    file.write("// prettier-ignore\n")
    file.write("uint[512] memory tmp_pk = [uint({}), {}];\n".format(
        sk.h[0], ','.join(map(str, sk.h[1:]))))
    file.write("uint[] memory pk = new uint[](512);\n")
    file.write("for (uint i = 0; i < 512; i++) {\n")
    file.write("\tpk[i] = tmp_pk[i];\n")
    file.write("}\n")

    file.write("// signature s1\n")
    file.write("// prettier-ignore\n")
    file.write("int[512] memory tmp_s1 = [int({}), {}];\n".format(
        s1[0], ','.join(map(str, s1[1:]))))
    file.write("Falcon.Signature memory sig;\n")
    file.write("sig.s1 = new int256[](512);\n")
    file.write("for (uint i = 0; i < 512; i++) {\n")
    file.write("\tsig.s1[i] = tmp_s1[i];\n")
    file.write("}\n")

    file.write("// signature s1 inverse\n")
    file.write("// prettier-ignore\n")
    file.write("int[512] memory tmp_s1_inv = [int({}), {}];\n".format(
        s1_inv[0], ','.join(map(str, s1_inv[1:]))))

    file.write("// message\n")
    file.write("bytes memory msg  = \"{}\"; \n".format(message))
    file.write('// salt and message hack because of Tetration confusion\n')
    file.write("sig.salt = msg;\nmsg = \"{}\"; \n".format(
        "".join(f"\\x{b:02x}" for b in salt)))
    file.write("falcon.verify(msg, sig, pk);\n")
    file.write("}\n")
file.write("}\n")
