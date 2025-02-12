import unittest
from keccak_prng import KeccakPRNG
from shake import SHAKE256


class TestKeccakPRNG(unittest.TestCase):
    """
    We follow the tests provided by Zhenfei Zhang here:
    https://github.com/zhenfeizhang/falcon-go/blob/main/c/test_prng.c
    """

    def shortDescription(self):
        return None  # This prevents unittest from printing docstrings

    def test_deterministic(self):
        """The PRNG is deterministic."""
        prng1 = KeccakPRNG()
        prng1.inject(b"test input")
        prng1.flip()
        output1 = prng1.extract(32)
        prng2 = KeccakPRNG()
        prng2.inject(b"test input")
        prng2.flip()
        output2 = prng2.extract(32)
        self.assertEqual(output1, output2)

    def test_change_with_size(self):
        """The PRNG is outputs different values for different sizes of output."""
        prng1 = KeccakPRNG()
        prng1.inject(b"test input")
        prng1.flip()
        output1 = prng1.extract(32)
        prng2 = KeccakPRNG()
        prng2.inject(b"test input")
        prng2.flip()
        output2 = prng2.extract(64)
        self.assertNotEqual(output1, output2)

    def test_inject_decomposition(self):
        """Check that injecting `testinput` or `test` and ten `input` produces the same output."""
        prng1 = KeccakPRNG()
        prng1.inject(b"testinput")
        prng1.flip()
        output1 = prng1.extract(32)

        prng2 = KeccakPRNG()
        prng2.inject(b"test")
        prng2.inject(b"input")
        prng2.flip()
        output2 = prng2.extract(32)

        self.assertEqual(output1, output2)

    def test_extraction(self):
        """Check that three extractions lead to different outputs."""
        prng = KeccakPRNG()
        prng.inject(b"test sequence")
        prng.flip()
        output1 = prng.extract(32)
        output2 = prng.extract(32)
        output3 = prng.extract(32)
        self.assertNotEqual(output1, output2)
        self.assertNotEqual(output2, output3)
        self.assertNotEqual(output1, output3)

    def test_structure_like_shake(self):
        """Check that the two XOF work with the same structure."""
        for xof in [KeccakPRNG, SHAKE256]:
            prng = xof()
            prng.update(b"Test of update")
            prng.flip()
            prng.read(32)
        self.assertTrue(True)

    def test_small_read(self):
        """Check that we can read two bytes as in Falcon."""
        prng = KeccakPRNG()
        prng.update(b"Test of update")
        prng.read(2)
        self.assertTrue(True)
