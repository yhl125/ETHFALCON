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

    def test_absorb_twice(self):
        message1 = b"We are "
        message2 = b" ZKNOX."
        message = message1 + message2

        K = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
        K.absorb(message)
        K.pad()
        output_1 = K.squeeze(32)

        L = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
        L.absorb(message1)
        L.absorb(message2)
        L.pad()
        output_2 = L.squeeze(32)
        self.assertEqual(output_1, output_2)

    def test_pad_necessary(self):
        message = b"This is a test of padding"
        K = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
        K.absorb(message)
        # K.pad()
        output = K.squeeze(32)
        self.assertEqual(
            output, bytes.fromhex("0000000000000000000000000000000000000000000000000000000000000000"))
