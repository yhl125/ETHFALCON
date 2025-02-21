import unittest

from falcon_epervier import EpervierSecretKey
from scripts.sign_KAT import sign_KAT
from shake import SHAKE


class TestRecoveryMode(unittest.TestCase):
    def test_signature_epervier(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = EpervierSecretKey(n, [f, g, F, G])
        message = b"abc"
        sig = sk.sign(message)
        pk_rec = sk.recover(message, sig)
        self.assertEqual(sk.pk, pk_rec)

    def test_signature_epervier_shake(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = EpervierSecretKey(n, [f, g, F, G])
        message = b"abc"
        sig = sk.sign(message, xof=SHAKE)
        pk_rec = sk.recover(message, sig, xof=SHAKE)
        self.assertEqual(sk.pk, pk_rec)
