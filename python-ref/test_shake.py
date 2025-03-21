from Crypto.Hash import keccak as PyCryptoKeccak
from Crypto.Hash import SHAKE256
from shake import SHAKE
from keccak import KeccakHash
from Crypto.Hash import SHAKE256
import os
import unittest
from random import randint
from time import time


class TestShake(unittest.TestCase):

    def test_vs_pycryptodome(self):
        for _ in range(10):
            output_size = randint(1, 100)
            message = os.urandom(123)

            # Using PyCryptoDome
            shake = SHAKE256.new()
            shake.update(message)
            output_1 = shake.read(output_size)

            # Using our implementation
            s = SHAKE.new()
            s.update(message)
            s.flip()
            output_2 = s.read(output_size)

            # Assert that it matches
            self.assertEqual(output_1, output_2)
