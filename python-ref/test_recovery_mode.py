import unittest

from falcon import PublicKey, SecretKey, RecoveryModeSecretKey
from scripts.sign_KAT import sign_KAT


class TestRecoveryMode(unittest.TestCase):
    def test_signature_recovery_mode(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        pk = PublicKey(sk)
        message = b"abc"
        sig = sk.sign_with_recovery(message)
        self.assertTrue(sk.verify_with_recovery(message, sig))
