from falcon import HEAD_LEN, SALT_LEN, Params, decompress, SecretKey, PublicKey
from polyntt.poly import Poly
from common import q
from scripts.sign_KAT import sign_KAT
from keccaxof import KeccaXOF

n = 512
f = sign_KAT[n][0]["f"]
g = sign_KAT[n][0]["g"]
F = sign_KAT[n][0]["F"]
G = sign_KAT[n][0]["G"]
sk = SecretKey(n, [f, g, F, G])
pub = PublicKey(sk)

for (i, message) in enumerate(["My name is Renaud", "My name is Simon"]):
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

# NOT WORKING FOR NOW
