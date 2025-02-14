from falcon_epervier import EpervierSecretKey
from falcon_recovery import RecoveryModeSecretKey
from scripts.sign_KAT import sign_KAT
from timeit import default_timer as timer


class BenchSignature():
    def bench_recovery_epervier(self):
        n = 512
        iterations = 1000
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        message = b"abc"
        # Falcon Rec
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        sig = sk.sign(message)
        assert sk.verify(message, sig)
        t1 = timer()
        for i in range(iterations):
            sk.verify(message, sig)
        t2 = timer()
        print("Verification FalconRec: {:.1f}ms".format(
            (t2-t1)/iterations * 10**3))
        # Epervier
        sk = EpervierSecretKey(n, [f, g, F, G])
        sig = sk.sign(message)
        assert sk.verify(message, sig)
        t3 = timer()
        for i in range(iterations):
            sk.verify(message, sig)
        t4 = timer()
        print("Verification Epervier: {:.1f}ms".format(
            (t4-t3)/iterations * 10**3))


B = BenchSignature()
B.bench_recovery_epervier()
