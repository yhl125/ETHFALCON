import unittest

from falcon_recovery import RecoveryModeSecretKey
from scripts.sign_KAT import sign_KAT
from keccak_prng import KeccakPRNG


class TestRecoveryMode(unittest.TestCase):
    def test_signature_recovery_mode(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        message = b"abc"
        sig = sk.sign_with_recovery(message)
        self.assertTrue(sk.verify_with_recovery(message, sig))

    def test_signature_recovery_mode_keccak_prng(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        message = b"abc"
        sig = sk.sign_with_recovery(message, xof=KeccakPRNG)
        self.assertTrue(sk.verify_with_recovery(message, sig, xof=KeccakPRNG))
