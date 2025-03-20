from Crypto.Hash import keccak as PyCryptoKeccak
from keccak import KeccakHash
import os
import unittest

output_test_input_32 = "5b9e99370fa4b753ac6bf0d246b3cec353c84a67839f5632cb2679b4ae565601"


class TestKeccakPRNG(unittest.TestCase):

    def test_versus_pycryptodome(self):
        for _ in range(10):
            message = os.urandom(123)

            # Keccak with our implementation
            K = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
            K.absorb(message)
            K.pad()
            output_1 = K.squeeze(32)

            # Keccak with pycryptodome implementation
            k = PyCryptoKeccak.new(digest_bytes=32)
            k.update(message)
            output_2 = k.digest()

            # Assert that it matches
            self.assertEqual(output_1, output_2)
