from Crypto.Hash import SHAKE256


class SHAKE:
    def __init__(self):
        self.shake = SHAKE256.new()

    @classmethod
    def new(self):
        return self()

    def update(self, data):
        self.shake.update(data)

    def read(self, length):
        return self.shake.read(length)

    def flip(self):
        return
