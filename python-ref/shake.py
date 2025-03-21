from keccak import KeccakHash


class SHAKE:
    def __init__(self, data=''):
        self.shake = KeccakHash(rate=200-(512 // 8), b=data, dsbyte=0x1f)

    @classmethod
    def new(self, data=''):
        return self(data)

    def update(self, data):
        self.shake.absorb(data)

    def read(self, length):
        return self.shake.squeeze(length)

    def flip(self):
        self.shake.pad()
        return
