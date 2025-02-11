from Crypto.Hash import keccak
import struct

# We implement the Keccak PRNG defined here:
# https://github.com/zhenfeizhang/falcon-go/blob/main/c/keccak_prng.c


# Constants
MAX_BUFFER_SIZE = 64  # Adjust based on needs
KECCAK_OUTPUT = 32  # Keccak output size in bytes


class KeccakPRNG:
    def __init__(self):
        """ Initialize a Keccak PRNG context. """
        self.buffer = bytearray(MAX_BUFFER_SIZE)
        self.state = bytearray(KECCAK_OUTPUT)
        self.buffer_len = 0
        self.counter = 0
        self.finalized = False

    @classmethod
    def new(self):
        return self()

    def inject(self, data: bytes):
        """ Inject (absorb) data into the PRNG state. """
        if self.finalized:
            raise ValueError("Cannot inject after finalizing")

        if len(data) + self.buffer_len > MAX_BUFFER_SIZE:
            raise ValueError("Buffer overflow")

        self.buffer[self.buffer_len:self.buffer_len + len(data)] = data
        self.buffer_len += len(data)

    def flip(self):
        """ Finalize the PRNG state and prepare for output generation. """
        if self.finalized:
            raise ValueError("Already finalized")

        keccak_ctx = keccak.new(digest_bytes=KECCAK_OUTPUT)
        keccak_ctx.update(self.buffer[:self.buffer_len])

        # Generate initial state
        self.state = keccak_ctx.digest()
        self.finalized = True

    def extract(self, length: int) -> bytes:
        """ Generate pseudorandom output from the PRNG. """
        if not self.finalized:
            raise ValueError("PRNG not finalized")

        output = bytearray()

        while len(output) < length:
            # Prepare input block: state || counter (big-endian)
            block = self.state + struct.pack(">Q", self.counter)

            # Generate next block using Keccak
            keccak_ctx = keccak.new(digest_bytes=KECCAK_OUTPUT)
            keccak_ctx.update(block)
            squeeze_out = keccak_ctx.digest()

            # Append to output
            to_copy = min(length - len(output), KECCAK_OUTPUT)
            output.extend(squeeze_out[:to_copy])

            self.counter += 1

        return bytes(output)

    # Two functions to keep the structure of SHAKE256
    def update(self, data: bytes):
        """`update` is `inject` in Zhenfei specification."""
        self.inject(data)

    def read(self, length: int) -> bytes:
        """flip and extract"""
        self.flip()
        return self.extract(length)
