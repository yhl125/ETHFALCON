from falcon_recovery import HEAD_LEN, SALT_LEN, compress, decompress, RecoveryModeSecretKey
from falcon import Params
from common import q
from scripts.sign_KAT import sign_KAT
from keccaxof import KeccaXOF

n = 512
sk = RecoveryModeSecretKey(n)

salt = "Send ______ 1 USDC ______ to vitalik.eth"
message = " and 50000 USDC to RektMe.eth!"


def constant_salt(x):
    return salt.encode()


σ = sk.sign(message.encode(), randombytes=constant_salt, xof=KeccaXOF)

pk = sk.pk
assert pk == sk.recover(message.encode(), σ, xof=KeccaXOF)

print('ok')

enc_s = σ[HEAD_LEN+SALT_LEN: -n*3]
s = decompress(enc_s, Params[n]["sig_bytelen"] * 2 - HEAD_LEN - SALT_LEN, n*2)
mid = len(s)//2
s0, s1 = s[:mid], s[mid:]

s0_new, s1_new = [-elt for elt in s0], [-elt for elt in s1]

print('new s0s1')
enc_s_new = compress(
    s0_new + s1_new, Params[n]['sig_bytelen']*2 - HEAD_LEN - SALT_LEN
)
print('comrpessed')
σ_new = σ[:HEAD_LEN+SALT_LEN] + σ[HEAD_LEN:HEAD_LEN + SALT_LEN] + enc_s_new

print('start rec')
assert pk == sk.recover(message.encode(), σ_new, xof=KeccaXOF)
print('ok')
