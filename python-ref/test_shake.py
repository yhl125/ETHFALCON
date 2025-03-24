from Crypto.Hash import SHAKE256 as PyCryptoDomeShake
from shake import SHAKE
import os
import unittest
from random import randint


class TestShake(unittest.TestCase):

    def test_vs_pycryptodome(self):
        for _ in range(10):
            output_size = randint(1, 100)
            message = os.urandom(123)

            # Using PyCryptoDome
            shake = PyCryptoDomeShake.new()
            shake.update(message)
            output_1 = shake.read(output_size)

            # Using our implementation
            s = SHAKE.new()
            s.update(message)
            s.flip()
            output_2 = s.read(output_size)

            # Assert that it matches
            self.assertEqual(output_1, output_2)

    def test_for_renaud(self):
        from binascii import unhexlify as unhx
        # from coruus test vectors
        message = "B32D95B0B9AAD2A8816DE6D06D1F86008505BD8C14124F6E9A163B5A2ADE55F835D0EC3880EF50700D3B25E42CC0AF050CCD1BE5E555B23087E04D7BF9813622780C7313A1954F8740B6EE2D3F71F768DD417F520482BD3A08D4F222B4EE9DBD015447B33507DD50F3AB4247C5DE9A8ABD62A8DECEA01E3B87C8B927F5B08BEB37674C6F8E380C04"
        expected = "cc2eaa04eef8479cdae8566eb8ffa1100a407995bf999ae97ede526681dc3490616f28442d20da92124ce081588b81491aedf65caaf0d27e82a4b0e1d1cab23833328f1b8da430c8a08766a86370fa848a79b5998db3cffd057b96e1e2ee0ef229eca133c15548f9839902043730e44bc52c39fadc1ddeead95f9939f220ca300661540df7edd9af378a5d4a19b2b93e6c78f49c353343a0b5f119132b5312d004831d01769a316d2f51bf64ccb20a21c2cf7ac8fb6f6e90706126bdae0611dd13962e8b53d6eae26c7b0d2551daf6248e9d65817382b04d23392d108e4d3443de5adc7273c721a8f8320ecfe8177ac067ca8a50169a6e73000ebcdc1e4ee6339fc867c3d7aeab84146398d7bade121d1989fa457335564e975770a3a00259ca08706108261aa2d34de00f8cac7d45d35e5aa63ea69e1d1a2f7dab3900d51e0bc65348a25554007039a52c3c309980d17cad20f1156310a39cd393760cfe58f6f8ade42131288280a35e1db8708183b91cfaf5827e96b0f774c45093b417aff9dd6417e59964a01bd2a612ffcfba18a0f193db297b9a6cc1d270d97aae8f8a3a6b26695ab66431c202e139d63dd3a24778676cefe3e21b02ec4e8f5cfd66587a12b44078fcd39eee44bbef4a949a63c0dfd58cf2fb2cd5f002e2b0219266cfc031817486de70b4285a8a70f3d38a61d3155d99aaf4c25390d73645ab3e8d80f0"
        # using our shake implementation
        shake = SHAKE.new(data='')
        shake.update(unhx(message.lower()))
        shake.flip()
        self.assertEqual(shake.read(1088).hex()[0:1024], expected)

    def test_read_twice(self):
        from binascii import unhexlify as unhx
        # from coruus test vectors
        message = b"Hello my friend"
        # two reads
        shake = SHAKE.new(data='')
        shake.update(message)
        shake.flip()
        shake.read(2)
        out1 = shake.read(2)
        # one read
        shake = SHAKE.new(data='')
        shake.update(message)
        shake.flip()
        out2 = shake.read(4)
        self.assertEqual(out1, out2[2:4])

    def test_debug_h2p(self):
        from binascii import unhexlify as unhx
        salt = "77231395f6147293b68ceab7a9e0c58d864e8efde4e1b9a46cbe854713672f5caaae314ed9083dab"
        msg = "4d79206e616d652069732052656e617564"
        res = "ba50d4292b44271cadce6b8292cb0a4c885cff02317a4682b57be831fe8e9cea314a22913070dcf1317b4d34e8504d616015690c03c08e2614828dc27b382fd3f985bf8860d8577a0a5de93a66c53c65aec37d593b24a452e1b37203768228ed280f230473933486f793e94927783aa929c6bf3a056c59d6c2d971a0ac57e7d77167acc582ffec3c"
        shake = SHAKE.new(data='')
        shake.update(unhx(salt.lower()))
        shake.update(unhx(msg.lower()))
        shake.flip()
        self.assertEqual(shake.read(136).hex(), res)
