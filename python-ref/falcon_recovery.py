"""Python implementation of Recovery Falcon"""
from common import q
from encoding import compress, decompress
from falcon import HEAD_LEN, SALT_LEN, SEED_LEN, SecretKey, logn
from keccak_prng import KeccakPRNG
from polyntt.poly import Poly
from Crypto.Hash import keccak
# Randomness
from os import urandom


class RecoveryModeSecretKey(SecretKey):
    def __init__(self, n, polys=None, ntt='NTTIterative'):
        super().__init__(n, polys, ntt)
        keccak_ctx = keccak.new(digest_bytes=32)
        keccak_ctx.update(b''.join(x.to_bytes(3, 'big') for x in self.h))
        self.pk = keccak_ctx.digest()

    def sign(self, message, randombytes=urandom, xof=KeccakPRNG):
        """
        Sign a message. The message MUST be a byte string or byte array.
        Optionally, one can select the source of (pseudo-)randomness used
        (default: urandom).
        """
        int_header = 0x30 + logn[self.n]
        header = int_header.to_bytes(1, "little")

        salt = randombytes(SALT_LEN)
        hashed = self.hash_to_point(message, salt, xof=xof)

        # We repeat the signing procedure until we find a signature that is
        # short enough (both the Euclidean norm and the bytelength)
        while (1):
            if (randombytes == urandom):
                s = self.sample_preimage(hashed)
            else:
                seed = randombytes(SEED_LEN)
                s = self.sample_preimage(hashed, seed=seed)
            # We need s1 to be invertible
            # TODO: is it secure to do so?
            s_1_ntt = Poly(s[1], q).ntt()
            if all(elt % q != 0 for elt in s_1_ntt):
                norm_sign = sum(coef ** 2 for coef in s[0])
                norm_sign += sum(coef ** 2 for coef in s[1])
                # Check the Euclidean norm
                if norm_sign <= self.signature_bound:
                    # We compress here s[0] and s[1], not s_1_inv_ntt.
                    enc_s = compress(
                        s[0]+s[1], self.sig_bytelen * 2 - HEAD_LEN - SALT_LEN)
                    s_1_inv = Poly(s[1], q).inverse().coeffs
                    # 3 * n bytes required for s1_inv
                    bytes_s1_inv = b''.join(x.to_bytes(3, 'big')
                                            for x in s_1_inv)
                    # Check that the encoding is valid (sometimes it fails)
                    if enc_s is not False:
                        return header + salt + enc_s + bytes_s1_inv

    def verify(self, message, signature, ntt='NTTIterative', xof=KeccakPRNG):
        """
        Verify a signature.
        """
        # Unpack the salt and the short polynomial s1
        salt = signature[HEAD_LEN:HEAD_LEN + SALT_LEN]
        enc_s = signature[HEAD_LEN+SALT_LEN:-self.n*3]
        s = decompress(enc_s, self.sig_bytelen * 2 -
                       HEAD_LEN - SALT_LEN, self.n*2)
        # Check that the encoding is valid
        if (s is False):
            print("Invalid encoding")
            return False
        mid = len(s)//2
        s0, s1 = s[:mid], s[mid:]
        # s_1_inv
        byte_s_1_inv = signature[-self.n*3:]
        s_1_inv = Poly([int.from_bytes(byte_s_1_inv[i:i+3], 'big')
                        for i in range(0, len(byte_s_1_inv), 3)], q)

        # check that s_1_inv * s_1 == 1
        if (s_1_inv * Poly(s1, q)).coeffs != [1] + [0 for i in range(len(s1)-1)]:
            return False

        # Check that the (s0, s1) is short
        norm_sign = sum(coef ** 2 for coef in s0)
        norm_sign += sum(coef ** 2 for coef in s1)
        if norm_sign > self.signature_bound:
            print("Squared norm of signature is too large:", norm_sign)
            return False

        # Compute s0 and normalize its coefficients in (-q/2, q/2]
        hashed = Poly(self.hash_to_point(message, salt, xof=xof), q, ntt=ntt)
        s0 = Poly(s0, q, ntt=ntt)
        # recover h
        h = (hashed - s0) * s_1_inv
        bytes_h = b''.join(x.to_bytes(3, 'big') for x in h.coeffs)
        keccak_ctx = keccak.new(digest_bytes=32)
        keccak_ctx.update(bytes_h)
        if self.pk != keccak_ctx.digest():
            return False
        # If all checks are passed, accept
        return True
