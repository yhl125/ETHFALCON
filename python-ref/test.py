"""
This file implements tests for various parts of the Falcon.py library.

Test the code with:
> make test
"""
from polyntt import poly
from timeit import default_timer as timer
from scripts.samplerz_KAT1024 import sampler_KAT1024
from scripts.sign_KAT import sign_KAT
from scripts.samplerz_KAT512 import sampler_KAT512
from scripts import saga
from encoding import compress, decompress
from falcon import SALT_LEN, HEAD_LEN
from Crypto.Hash import SHAKE256
from keccaxof import KeccaXOF
from falcon import SecretKey, PublicKey, Params
from ntrugen import karamul, ntru_gen, gs_norm
from math import sqrt, ceil
from random import randint, random, gauss, uniform
from ffsampling import gram
from ffsampling import ffldl, ffldl_fft, ffnp, ffnp_fft
from samplerz import samplerz, MAX_SIGMA
from fft import add, sub, mul, div, neg, fft, ifft
from common import q, sqnorm


def vecmatmul(t, B):
    """Compute the product t * B, where t is a vector and B is a square matrix.

    Args:
        B: a matrix

    Format: coefficient
    """
    nrows = len(B)
    ncols = len(B[0])
    deg = len(B[0][0])
    assert (len(t) == nrows)
    v = [[0 for k in range(deg)] for j in range(ncols)]
    for j in range(ncols):
        for i in range(nrows):
            v[j] = add(v[j], mul(t[i], B[i][j]))
    return v


def test_fft(n, iterations=10):
    """Test the FFT."""
    for i in range(iterations):
        f = [randint(-3, 4) for j in range(n)]
        g = [randint(-3, 4) for j in range(n)]
        h = mul(f, g)
        k = div(h, f)
        k = [int(round(elt)) for elt in k]
        if k != g:
            print("(f * g) / f =", k)
            print("g =", g)
            print("mismatch")
            return False
    return True


def test_ntt(n, iterations=10):
    """Test the NTT."""
    for i in range(iterations):
        for ntt in ['NTTIterative', 'NTTRecursive']:
            f = poly.Poly([randint(0, q-1) for j in range(n)], q, ntt=ntt)
            g = poly.Poly([randint(0, q-1) for j in range(n)], q, ntt=ntt)
            h = f*g
            try:
                k = h.div(f)
                if k != g:
                    print("(f * g) / f =", k)
                    print("g =", g)
                    print("mismatch")
                    return False
            except ZeroDivisionError:
                continue
    return True


def check_ntru(f, g, F, G):
    """Check that f * G - g * F = q mod (x ** n + 1)."""
    a = karamul(f, G)
    b = karamul(g, F)
    c = [a[i] - b[i] for i in range(len(f))]
    return ((c[0] == q) and all(coef == 0 for coef in c[1:]))


def test_ntrugen(n, iterations=10):
    """Test ntru_gen."""
    for i in range(iterations):
        f, g, F, G = ntru_gen(n)
        if check_ntru(f, g, F, G) is False:
            return False
    return True


def test_ffnp(n, iterations):
    """Test ffnp.

    This functions check that:
    1. the two versions (coefficient and FFT embeddings) of ffnp are consistent
    2. ffnp output lattice vectors close to the targets.
    """
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    B = [[g, neg(f)], [G, neg(F)]]
    G0 = gram(B)
    G0_fft = [[fft(elt) for elt in row] for row in G0]
    T = ffldl(G0)
    T_fft = ffldl_fft(G0_fft)

    sqgsnorm = gs_norm(f, g, q)
    m = 0
    for i in range(iterations):
        t = [[random() for i in range(n)], [random() for i in range(n)]]
        t_fft = [fft(elt) for elt in t]

        z = ffnp(t, T)
        z_fft = ffnp_fft(t_fft, T_fft)

        zb = [ifft(elt) for elt in z_fft]
        zb = [[round(coef) for coef in elt] for elt in zb]
        if z != zb:
            print("ffnp and ffnp_fft are not consistent")
            return False
        diff = [sub(t[0], z[0]), sub(t[1], z[1])]
        diffB = vecmatmul(diff, B)
        norm_zmc = int(round(sqnorm(diffB)))
        m = max(m, norm_zmc)
    th_bound = (n / 4.) * sqgsnorm
    if m > th_bound:
        print("Warning: ffnp does not output vectors as short as expected")
        return False
    else:
        return True


def test_compress(n, iterations):
    """Test compression and decompression."""
    try:
        sigma = 1.5 * sqrt(q)
        slen = Params[n]["sig_bytelen"] - SALT_LEN - HEAD_LEN
    except KeyError:
        return True
    for i in range(iterations):
        while (1):
            initial = [int(round(gauss(0, sigma))) for coef in range(n)]
            compressed = compress(initial, slen)
            if compressed is not False:
                break
        decompressed = decompress(compressed, slen, n)
        if decompressed != initial:
            return False
    return True


def test_samplerz(nb_mu=100, nb_sig=100, nb_samp=1000):
    """
    Test our Gaussian sampler on a bunch of samples.
    This is done by using a light version of the SAGA test suite,
    see ia.cr/2019/1411.
    """
    # Minimal size of a bucket for the chi-squared test (must be >= 5)
    chi2_bucket = 10
    assert (nb_samp >= 10 * chi2_bucket)
    sigmin = 1.3
    nb_rej = 0
    for i in range(nb_mu):
        mu = uniform(0, q)
        for j in range(nb_sig):
            sigma = uniform(sigmin, MAX_SIGMA)
            list_samples = [samplerz(mu, sigma, sigmin)
                            for _ in range(nb_samp)]
            v = saga.UnivariateSamples(mu, sigma, list_samples)
            if (v.is_valid is False):
                nb_rej += 1
    return True
    if (nb_rej > 5 * ceil(saga.pmin * nb_mu * nb_sig)):
        return False
    else:
        return True


def KAT_randbytes(k):
    """
    Use a fixed bytestring 'octets' as a source of random bytes
    """
    global octets
    oc = octets[: (2 * k)]
    if len(oc) != (2 * k):
        raise IndexError("Randomness string out of bounds")
    octets = octets[(2 * k):]
    return bytes.fromhex(oc)[::-1]


def test_samplerz_KAT(unused, unused2):
    # octets is a global variable used as samplerz's randomness.
    # It is set to many fixed values by test_samplerz_KAT,
    # then used as a randomness source via KAT_randbits.
    global octets
    for D in sampler_KAT512 + sampler_KAT1024:
        mu = D["mu"]
        sigma = D["sigma"]
        sigmin = D["sigmin"]
        # Hard copy. octets is the randomness source for samplez
        octets = D["octets"][:]
        exp_z = D["z"]
        try:
            z = samplerz(mu, sigma, sigmin, randombytes=KAT_randbytes)
        except IndexError:
            return False
        if (exp_z != z):
            print("SamplerZ does not match KATs")
            return False
    return True


def test_signature(n, iterations=10):
    """
    Test Falcon.
    """
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    pk = PublicKey(sk)
    for i in range(iterations):
        message = b"abc"
        sig = sk.sign(message)
        if pk.verify(message, sig) is False:
            return False
    return True


def test_keygen_different_ntt(n, iterations=100):
    """Test Falcon key generation."""
    d = {True: "OK    ", False: "Not OK"}
    for ntt in ['NTTIterative', 'NTTRecursive']:
        start = timer()
        for i in range(iterations):
            sk = SecretKey(n, polys=None, ntt=ntt)
            # pk = PublicKey(sk)
        rep = True
        end = timer()

        msg = "Test keygen ({})".format(ntt[3:])
        msg = msg.ljust(20) + ": " + d[rep]
        if rep is True:
            diff = end - start
            msec = round(diff * 1000 / iterations, 3)
            msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
        print(msg)


def test_verif_different_ntt(n, iterations=100):
    """Test Falcon signature verification."""
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    pk = PublicKey(sk)
    message = b"abc"
    sig = sk.sign(message)

    d = {True: "OK    ", False: "Not OK"}
    for ntt in ['NTTIterative', 'NTTRecursive']:
        start = timer()
        for i in range(iterations):
            if pk.verify(message, sig, ntt=ntt) is False:
                rep = False
        rep = True
        end = timer()

        msg = "Test verif ({})".format(ntt[3:])
        msg = msg.ljust(20) + ": " + d[rep]
        if rep is True:
            diff = end - start
            msec = round(diff * 1000 / iterations, 3)
            msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
        print(msg)


def test_signing_different_xof(n, iterations=100):
    """Test Falcon signature verification."""
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    pk = PublicKey(sk)
    message = b"abc"

    d = {True: "OK    ", False: "Not OK"}
    for (xof, xof_str) in [(SHAKE256, 'SHAKE256'), (KeccaXOF, 'KeccaXOF')]:
        start = timer()
        for i in range(iterations):
            sig = sk.sign(message, xof=xof)
        rep = True
        end = timer()

        msg = "Test sign ({})".format(xof_str)
        msg = msg.ljust(20) + ": " + d[rep]
        if rep is True:
            diff = end - start
            msec = round(diff * 1000 / iterations, 3)
            msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
        print(msg)


def test_verif_different_xof(n, iterations=100):
    """Test Falcon signature verification."""
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    pk = PublicKey(sk)
    message = b"abc"
    sigs = {
        'SHAKE256': sk.sign(message, xof=SHAKE256),
        'KeccaXOF': sk.sign(message, xof=KeccaXOF)
    }

    d = {True: "OK    ", False: "Not OK"}
    for (xof, xof_str) in [(SHAKE256, 'SHAKE256'), (KeccaXOF, 'KeccaXOF')]:
        start = timer()
        for i in range(iterations):
            if pk.verify(message, sigs[xof_str], xof=xof) is False:
                rep = False
        rep = True
        end = timer()

        msg = "Test verif ({})".format(xof_str)
        msg = msg.ljust(20) + ": " + d[rep]
        if rep is True:
            diff = end - start
            msec = round(diff * 1000 / iterations, 3)
            msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
        print(msg)


def test_sign_KAT():
    """
    Test the signing procedure against test vectors obtained from
    the Round 3 implementation of Falcon.

    Starting from the same private key, same message, and same SHAKE256
    context (for randomness generation), we check that we obtain the
    same signatures.
    """
    message = b"data1"
    shake = SHAKE256.new(b"external")
    for n in sign_KAT:
        sign_KAT_n = sign_KAT[n]
        for D in sign_KAT_n:
            f = D["f"]
            g = D["g"]
            F = D["F"]
            G = D["G"]
            sk = SecretKey(n, [f, g, F, G])
            # The next line is done to synchronize the SHAKE256 context
            # with the one in the Round 3 C implementation of Falcon.
            _ = shake.read(8 * D["read_bytes"])
            sig = sk.sign(message, shake.read)
            if sig != bytes.fromhex(D["sig"]):
                return False
    return True


def wrapper_test(my_test, name, n, iterations):
    """
    Common wrapper for tests. Run the test, print whether it is successful,
    and if it is, print the running time of each execution.
    """
    d = {True: "OK    ", False: "Not OK"}
    start = timer()
    rep = my_test(n, iterations)
    end = timer()
    message = "Test {name}".format(name=name)
    message = message.ljust(20) + ": " + d[rep]
    if rep is True:
        diff = end - start
        msec = round(diff * 1000 / iterations, 3)
        message += " ({msec} msec / execution)".format(msec=msec).rjust(30)
    print(message)


# Dirty trick to fit test_samplerz into our test wrapper
def test_samplerz_simple(n, iterations):
    return test_samplerz(10, 10, iterations // 100)


def test_hash_to_point(n):
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    message = b"def"
    salt = b"abc"
    xof = KeccaXOF
    hash = sk.hash_to_point(message, salt, xof=xof)
    assert hash == [7373, 883, 5550, 2322, 8580, 11319, 1037, 9708, 7159, 4158, 683, 1120, 9948, 11269, 790, 6252, 2698, 12217, 3596, 1819, 10441, 8257, 3040, 5573, 5213, 5150, 6123, 4363, 10505, 3359, 363, 10882, 4000, 3996, 2150, 6823, 8209, 10781, 11953, 397, 10576, 5527, 239, 7733, 8493, 3126, 3301, 10385, 7235, 8080, 1175, 6491, 11269, 3618, 3479, 1771, 406, 5245, 9874, 10195, 6777, 5908, 10147, 2321, 71, 5157, 6106, 9459, 7587, 7005, 10808, 9396, 6657, 10692, 11888, 10688, 9776, 6123, 11708, 6919, 1184, 3832, 4832, 6274, 5330, 7664, 9929, 4401, 8412, 7710, 1733, 8158, 8469, 10972, 8546, 10418, 1032, 5926, 6686, 1606, 2094, 6147, 4268, 2856, 9724, 8827, 2276, 327, 364, 3546, 5060, 38, 6461, 7825, 11703, 10229, 586, 6232, 5538, 8703, 9068, 1751, 1261, 10886, 8971, 10072, 4803, 12269, 11905, 1677, 168, 2793, 2446, 5598, 8609, 4471, 10206, 1457, 3344, 2115, 6331, 11897, 1509, 8496, 12033, 3422, 10769, 11981, 6746, 7141, 94, 5401, 5412, 7172, 4080, 1804, 5720, 7593, 8985, 1068, 866, 2872, 1144, 8687, 1395, 3877, 6666, 380, 1886, 8886, 3537, 6025, 4523, 11893, 2189, 9675, 9704, 2827, 4970, 1684, 6198, 9349, 2356, 9487, 9011, 6136, 2937, 7772, 8917, 5851, 5574, 4245, 1868, 3395, 11345, 9115, 6179, 8240, 170, 11821, 11009, 10257, 2003, 2154, 4612, 1906, 7653, 203, 6384, 437, 6531, 145, 10917, 2606, 6845, 8790, 700, 6949, 12030, 3271, 8790, 8978, 856, 963, 7089, 7632, 4568, 1919, 981, 8380, 3234, 8620, 9570, 6974, 3323, 9642, 11463, 7488, 12036, 9285, 2705, 10601, 10934, 6299, 2429, 5872, 2395, 8623, 10114, 2620, 2630, 590, 3967, 4556, 9924,
                    879, 2707, 4040, 6396, 3889, 4566, 8314, 6265, 9124, 11261, 5979, 11982, 1516, 1839, 8051, 2727, 11180, 7284, 8952, 6320, 2185, 12130, 2611, 7147, 8642, 333, 9797, 3864, 3853, 2205, 537, 2776, 6938, 10117, 3333, 5040, 4924, 7216, 862, 5323, 5855, 7323, 11256, 7123, 5614, 10247, 6583, 1246, 2875, 9923, 271, 2680, 4780, 3484, 907, 542, 9323, 6595, 12025, 7084, 3173, 10515, 7797, 9340, 4198, 877, 7058, 10517, 10104, 2880, 8175, 9685, 7269, 11157, 3314, 3034, 11799, 2551, 11904, 7429, 5751, 3132, 3452, 4780, 7713, 6464, 4353, 8079, 10272, 9572, 3381, 2148, 4100, 4467, 8107, 60, 609, 67, 11037, 478, 3026, 9156, 4803, 7480, 5859, 8840, 3731, 3487, 5738, 9166, 2234, 292, 5043, 6837, 7510, 7688, 2131, 11644, 12285, 4427, 6851, 5184, 5932, 242, 4802, 8613, 11136, 1682, 11256, 6734, 6703, 7082, 9114, 9563, 9119, 8417, 10026, 12245, 2885, 1798, 8815, 4490, 4079, 9728, 2595, 4923, 9698, 9093, 3926, 670, 4016, 10825, 1518, 8949, 909, 8707, 9346, 8743, 2106, 3059, 11835, 11278, 10934, 10177, 7263, 10275, 5048, 6952, 6250, 2353, 3920, 2781, 7631, 8632, 1223, 5428, 7385, 10594, 12115, 5957, 10539, 6384, 2624, 3349, 718, 8849, 228, 10276, 6353, 10616, 1686, 10242, 9974, 8008, 3376, 8098, 4266, 1021, 10080, 8667, 8964, 3002, 7628, 6421, 1920, 3720, 9781, 4655, 8790, 10767, 10205, 7210, 1727, 9543, 11341, 3906, 6320, 11588, 4259, 11000, 12284, 2957, 9151, 1844, 2047, 7067, 7948, 4312, 10967, 1997, 3450, 7, 9290, 10288, 5251, 2092, 3033, 10705, 9763, 12187, 4430, 6390, 3185, 12255, 287, 11098, 5316, 9010, 6996, 4205, 991, 2719, 6812, 8947, 7238, 4094, 2293]
    # assuming hash == s2...
    from polyntt.poly import Poly
    s2 = Poly(hash, q)
    print(s2.inverse().coeffs)


def test_simon(n):
    from falcon import HEAD_LEN, SALT_LEN, Params, compress, decompress
    from keccaxof import KeccaXOF
    from polyntt.poly import Poly
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    salt = b"\xc5\xb4\x0c'p\xa32 \x9f\x89\xd5\xc4\xf1\x106\x0e\xe8\x8b1\x0fU\xc6\xc7\n\xf5\x01\xee8:|\xe4r\xdb\xbd>\xff\xa0V\xac\x97"
    message = b"falcon in sol now?"
    hash = sk.hash_to_point(message, salt, xof=KeccaXOF)

    s1 = [-106, -186, 85, 41, 99, 67, -55, -23, 224, -302, -21, 78, -237, 196, 60, 469, -112, -90, 25, -80, -234, 196, 10, -67, 92, -130, -119, 123, -419, 73, 239, -20, 65, -293, 121, 31, -378, 360, -119, -7, -57, -321, -113, 160, -98, -101, 37, 105, -282, 157, -190, 154, 164, -131, -70, -99, -181, -59, -135, 423, -167, 130, 23, -23, -444, 228, 268, -94, 125, -18, 52, -12, -159, -17, 101, 192, 137, 264, 63, -135, -70, 130, -135, 149, -37, 101, -253, 21, -110, -202, -224, -130, -1, -217, 215, -54, -121, 123, 127, 177, -58, 19, 84, -51, -34, -198, 19, 157, -329, 118, -109, -339, 279, 138, 11, -202, 3, -106, -74, 257, -21, 215, 5, 211, -168, 67, 39, 231, 135, -157, 61, -12, -1, 45, -18, 77, 231, 167, 48, 28, -56, 159, -196, 88, 28, -126, 45, -104, -110, -92, -69, -277, -120, 19, -23, 44, -116, -119, -122, 326, -238, -8, 79, -63, 383, -16, 275, -10, 328, -126, 111, -58, 122, -191, -126, -169, 237, 175, -13, -64, -164, -98, -98, 196, 63, -117, 201, -282, 207, 288, -352, 251, 69, 111, -140, 52, 125, -129, 70, 250, -276, -185, 59, -60, 376, 287, 45, 133, -443, -253, 58, -305, 170, -47, -54, -244, 181, -270, -188, 158, -171, -64, -119, 246, 101, -52, 343, -129, 38, 196, 227, 101, -144, 20, 281, -119, -235, 239, 38, -69, 293, 176, -158, -98, -100, 6, -543, -161, 427, -277, -166, 14, -61, 164,
          170, -249, 76, -66, -101, 210, -306, 13, 47, 76, -293, 94, 114, -123, -102, -370, 87, -123, -52, -78, -12, 16, -29, 55, 60, 185, 131, -71, 230, 80, 157, -58, -442, 10, -98, 132, 3, 2, -28, 119, -212, 133, 205, -45, 160, -49, -186, 87, 228, 278, -248, 72, -86, -53, -286, 56, 3, -72, -20, 66, -28, -59, 225, 129, -197, 110, -237, 97, -53, 6, 83, -464, -221, 77, 7, -113, 86, 239, -198, 84, -372, 36, -260, -102, 101, -1, -177, -96, -238, -35, -98, 42, 205, -139, 20, -233, -117, -152, 114, -185, 52, 109, -12, -84, -12, 489, -274, 104, -22, 248, 144, -128, -106, 199, 99, -189, -100, -233, -266, -146, 383, 72, -216, -95, 86, 283, -254, -276, -61, -103, -264, -189, -71, 13, -186, 54, 179, 354, -159, 137, 22, 48, -101, 14, -13, -244, 5, 109, 230, 111, 151, 38, -171, 265, -30, -69, 79, -195, 126, 36, 24, 160, 214, -91, 85, -160, 157, 234, 390, 151, -189, -19, 324, -42, 82, -176, -111, 111, 113, -181, 123, -14, 165, 127, 172, -165, -328, -86, 16, -243, -174, 11, 73, 61, -12, -149, 33, -55, -287, -245, -234, -111, -40, -55, 162, -120, 213, -205, -163, -39, 444, 53, 166, 97, 47, 240, -194, -147, -139, 56, -142, 63, 147, -68, 36, -55, -62, -47, 39, -186, 133, -254, -162, -80, -75, 164, -197, -111, 199, 345, -171, -250, 252, 53, 179, 319, -192, 109, -277, 136, 15, 75, 18, -42, 353, -230, 70, 53]
    pk = [6018, 3543, 543, 3451, 10671, 4482, 686, 11742, 3415, 8727, 8346, 9831, 10529, 7539, 817, 345, 1502, 4029, 6252, 5831, 4746, 10403, 12236, 11638, 1823, 1067, 11978, 12242, 9126, 222, 12181, 5805, 6501, 279, 3744, 9274, 4303, 3886, 12198, 788, 2216, 4250, 7908, 866, 11036, 5740, 3060, 1013, 1838, 1033, 8210, 10076, 6110, 10074, 7337, 8444, 10786, 3896, 11651, 2785, 11071, 7373, 7605, 12005, 1815, 9786, 2707, 10461, 5076, 10760, 7898, 214, 7819, 2988, 5403, 5786, 7782, 4967, 1485, 8431, 2161, 6198, 3303, 4893, 4551, 8729, 4219, 2766, 3609, 7260, 7717, 9278, 2781, 3551, 11654, 4662, 9295, 8932, 703, 7512, 10652, 3087, 7435, 7609, 636, 10151, 8186, 8926, 6217, 8515, 4317, 9070, 8021, 112, 5118, 6354, 9730, 2490, 5543, 10978, 5998, 2816, 9513, 10413, 665, 9269, 10852, 7202, 4060, 10218, 11172, 7495, 10761, 2037, 368, 6840, 6401, 3539, 4243, 4462, 7141, 4922, 10212, 4506, 3515, 607, 8678, 58, 9219, 1049, 3309, 8025, 3604, 6768, 3923, 1631, 6558, 10884, 9873, 8973, 7710, 6599, 5347, 3952, 11553, 4299, 3501, 6107, 11964, 8840, 12117, 8935, 871, 206, 8813, 9492, 6658, 3414, 1813, 1563, 10985, 3386, 8258, 11771, 137, 1947, 402, 8573, 11692, 4560, 6780, 1847, 11025, 7583, 10636, 1508, 12073, 3769, 1343, 1459, 1492, 4788, 10543, 7433, 3017, 12021, 6709, 8841, 8915, 2581, 2236, 43, 5660, 11594, 3859, 9947, 8061, 11022, 2468, 8543, 6992, 7398, 10810, 7726, 7759, 7839, 11257, 6052, 10697, 4413, 11284, 2426, 5616, 3190, 10909, 5763, 9970, 12096, 4475, 2531, 7044, 1212, 12254, 10103, 11843, 1179, 11207, 1507, 8826, 2025, 4153, 5522, 6059, 209, 10101,
          11048, 5911, 9425, 8052, 8826, 5619, 5222, 10481, 715, 8399, 2998, 2110, 6083, 6884, 7407, 3448, 2647, 11712, 1792, 11533, 12231, 9903, 9770, 8510, 5454, 3000, 8313, 3537, 7397, 4839, 9368, 8833, 8206, 3095, 5681, 4251, 9681, 6293, 3977, 4371, 6125, 10412, 734, 12211, 10815, 1220, 536, 8485, 12211, 7079, 9028, 7578, 8756, 9417, 8496, 11056, 992, 232, 6939, 576, 1447, 6648, 9738, 6118, 5286, 2892, 8596, 3788, 3835, 4051, 5241, 2360, 805, 9394, 2902, 6737, 6475, 7215, 7472, 5319, 3931, 5836, 6675, 3184, 409, 3510, 1886, 2937, 3969, 5331, 11352, 9375, 3526, 4666, 2783, 2898, 9443, 5413, 9932, 12146, 106, 7786, 8432, 3896, 5774, 10267, 10637, 11736, 720, 8246, 5315, 1843, 9132, 3767, 4962, 8275, 3995, 1751, 10958, 9320, 5895, 11212, 10768, 5281, 2836, 741, 9307, 7364, 7648, 6495, 670, 4783, 7016, 11121, 11743, 12190, 12173, 3856, 5451, 9190, 2992, 3229, 5610, 11945, 10566, 3616, 3642, 1082, 10679, 10943, 8447, 4245, 8062, 7475, 3507, 6403, 5820, 1951, 7393, 5435, 1914, 4606, 7176, 8791, 8080, 6836, 203, 8688, 6196, 11082, 8418, 4159, 10065, 9518, 10849, 3548, 7517, 12117, 12062, 5318, 2206, 8745, 10125, 946, 4027, 11859, 3755, 4930, 334, 9639, 1200, 11752, 9867, 4148, 9773, 426, 3605, 6899, 11297, 1478, 8646, 9937, 4138, 9058, 10513, 1110, 1229, 333, 3792, 6196, 1018, 2759, 6198, 7834, 7356, 5865, 4891, 9753, 7980, 7374, 11477, 3977, 8122, 11368, 5604, 11705, 3119, 3373, 9551, 11358, 7787, 5378, 9668, 7671, 10048, 6177, 5341, 87, 11016, 6498, 11316, 10006, 9555, 11043, 3413, 11782, 6594, 2702, 2712, 8549, 8874, 10101, 1317, 2011, 8158, 11678, 9893]

    for i in range(512):
        if s1[i] < 0:
            s1[i] += q

    print("hash = {}".format(hash))
    s0 = (Poly(hash, q) - Poly(s1, q) * Poly(pk, q)).coeffs
    # print("s0 = {}".format(s0))
    for i in range(512):
        if s0[i] > 6144:
            s0[i] = q-s0[i]
        if s1[i] > 6144:
            s1[i] = q-s1[i]
    norm = 0
    for i in range(512):
        norm += s0[i]**2
        norm += s1[i]**2
    print(norm < Params[n]["sig_bound"])
    # still not working...


def test_simon2(n):
    from falcon import HEAD_LEN, SALT_LEN, Params, compress, decompress
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])

    # NTT = 'NTTRecursive'
    NTT = 'NTTIterative'
    message = "falcon in sol now?"
    s1 = [-106, -186, 85, 41, 99, 67, -55, -23, 224, -302, -21, 78, -237, 196, 60, 469, -112, -90, 25, -80, -234, 196, 10, -67, 92, -130, -119, 123, -419, 73, 239, -20, 65, -293, 121, 31, -378, 360, -119, -7, -57, -321, -113, 160, -98, -101, 37, 105, -282, 157, -190, 154, 164, -131, -70, -99, -181, -59, -135, 423, -167, 130, 23, -23, -444, 228, 268, -94, 125, -18, 52, -12, -159, -17, 101, 192, 137, 264, 63, -135, -70, 130, -135, 149, -37, 101, -253, 21, -110, -202, -224, -130, -1, -217, 215, -54, -121, 123, 127, 177, -58, 19, 84, -51, -34, -198, 19, 157, -329, 118, -109, -339, 279, 138, 11, -202, 3, -106, -74, 257, -21, 215, 5, 211, -168, 67, 39, 231, 135, -157, 61, -12, -1, 45, -18, 77, 231, 167, 48, 28, -56, 159, -196, 88, 28, -126, 45, -104, -110, -92, -69, -277, -120, 19, -23, 44, -116, -119, -122, 326, -238, -8, 79, -63, 383, -16, 275, -10, 328, -126, 111, -58, 122, -191, -126, -169, 237, 175, -13, -64, -164, -98, -98, 196, 63, -117, 201, -282, 207, 288, -352, 251, 69, 111, -140, 52, 125, -129, 70, 250, -276, -185, 59, -60, 376, 287, 45, 133, -443, -253, 58, -305, 170, -47, -54, -244, 181, -270, -188, 158, -171, -64, -119, 246, 101, -52, 343, -129, 38, 196, 227, 101, -144, 20, 281, -119, -235, 239, 38, -69, 293, 176, -158, -98, -100, 6, -543, -161, 427, -277, -166, 14, -61, 164,
          170, -249, 76, -66, -101, 210, -306, 13, 47, 76, -293, 94, 114, -123, -102, -370, 87, -123, -52, -78, -12, 16, -29, 55, 60, 185, 131, -71, 230, 80, 157, -58, -442, 10, -98, 132, 3, 2, -28, 119, -212, 133, 205, -45, 160, -49, -186, 87, 228, 278, -248, 72, -86, -53, -286, 56, 3, -72, -20, 66, -28, -59, 225, 129, -197, 110, -237, 97, -53, 6, 83, -464, -221, 77, 7, -113, 86, 239, -198, 84, -372, 36, -260, -102, 101, -1, -177, -96, -238, -35, -98, 42, 205, -139, 20, -233, -117, -152, 114, -185, 52, 109, -12, -84, -12, 489, -274, 104, -22, 248, 144, -128, -106, 199, 99, -189, -100, -233, -266, -146, 383, 72, -216, -95, 86, 283, -254, -276, -61, -103, -264, -189, -71, 13, -186, 54, 179, 354, -159, 137, 22, 48, -101, 14, -13, -244, 5, 109, 230, 111, 151, 38, -171, 265, -30, -69, 79, -195, 126, 36, 24, 160, 214, -91, 85, -160, 157, 234, 390, 151, -189, -19, 324, -42, 82, -176, -111, 111, 113, -181, 123, -14, 165, 127, 172, -165, -328, -86, 16, -243, -174, 11, 73, 61, -12, -149, 33, -55, -287, -245, -234, -111, -40, -55, 162, -120, 213, -205, -163, -39, 444, 53, 166, 97, 47, 240, -194, -147, -139, 56, -142, 63, 147, -68, 36, -55, -62, -47, 39, -186, 133, -254, -162, -80, -75, 164, -197, -111, 199, 345, -171, -250, 252, 53, 179, 319, -192, 109, -277, 136, 15, 75, 18, -42, 353, -230, 70, 53]
    pk = [6018, 3543, 543, 3451, 10671, 4482, 686, 11742, 3415, 8727, 8346, 9831, 10529, 7539, 817, 345, 1502, 4029, 6252, 5831, 4746, 10403, 12236, 11638, 1823, 1067, 11978, 12242, 9126, 222, 12181, 5805, 6501, 279, 3744, 9274, 4303, 3886, 12198, 788, 2216, 4250, 7908, 866, 11036, 5740, 3060, 1013, 1838, 1033, 8210, 10076, 6110, 10074, 7337, 8444, 10786, 3896, 11651, 2785, 11071, 7373, 7605, 12005, 1815, 9786, 2707, 10461, 5076, 10760, 7898, 214, 7819, 2988, 5403, 5786, 7782, 4967, 1485, 8431, 2161, 6198, 3303, 4893, 4551, 8729, 4219, 2766, 3609, 7260, 7717, 9278, 2781, 3551, 11654, 4662, 9295, 8932, 703, 7512, 10652, 3087, 7435, 7609, 636, 10151, 8186, 8926, 6217, 8515, 4317, 9070, 8021, 112, 5118, 6354, 9730, 2490, 5543, 10978, 5998, 2816, 9513, 10413, 665, 9269, 10852, 7202, 4060, 10218, 11172, 7495, 10761, 2037, 368, 6840, 6401, 3539, 4243, 4462, 7141, 4922, 10212, 4506, 3515, 607, 8678, 58, 9219, 1049, 3309, 8025, 3604, 6768, 3923, 1631, 6558, 10884, 9873, 8973, 7710, 6599, 5347, 3952, 11553, 4299, 3501, 6107, 11964, 8840, 12117, 8935, 871, 206, 8813, 9492, 6658, 3414, 1813, 1563, 10985, 3386, 8258, 11771, 137, 1947, 402, 8573, 11692, 4560, 6780, 1847, 11025, 7583, 10636, 1508, 12073, 3769, 1343, 1459, 1492, 4788, 10543, 7433, 3017, 12021, 6709, 8841, 8915, 2581, 2236, 43, 5660, 11594, 3859, 9947, 8061, 11022, 2468, 8543, 6992, 7398, 10810, 7726, 7759, 7839, 11257, 6052, 10697, 4413, 11284, 2426, 5616, 3190, 10909, 5763, 9970, 12096, 4475, 2531, 7044, 1212, 12254, 10103, 11843, 1179, 11207, 1507, 8826, 2025, 4153, 5522, 6059, 209, 10101,
          11048, 5911, 9425, 8052, 8826, 5619, 5222, 10481, 715, 8399, 2998, 2110, 6083, 6884, 7407, 3448, 2647, 11712, 1792, 11533, 12231, 9903, 9770, 8510, 5454, 3000, 8313, 3537, 7397, 4839, 9368, 8833, 8206, 3095, 5681, 4251, 9681, 6293, 3977, 4371, 6125, 10412, 734, 12211, 10815, 1220, 536, 8485, 12211, 7079, 9028, 7578, 8756, 9417, 8496, 11056, 992, 232, 6939, 576, 1447, 6648, 9738, 6118, 5286, 2892, 8596, 3788, 3835, 4051, 5241, 2360, 805, 9394, 2902, 6737, 6475, 7215, 7472, 5319, 3931, 5836, 6675, 3184, 409, 3510, 1886, 2937, 3969, 5331, 11352, 9375, 3526, 4666, 2783, 2898, 9443, 5413, 9932, 12146, 106, 7786, 8432, 3896, 5774, 10267, 10637, 11736, 720, 8246, 5315, 1843, 9132, 3767, 4962, 8275, 3995, 1751, 10958, 9320, 5895, 11212, 10768, 5281, 2836, 741, 9307, 7364, 7648, 6495, 670, 4783, 7016, 11121, 11743, 12190, 12173, 3856, 5451, 9190, 2992, 3229, 5610, 11945, 10566, 3616, 3642, 1082, 10679, 10943, 8447, 4245, 8062, 7475, 3507, 6403, 5820, 1951, 7393, 5435, 1914, 4606, 7176, 8791, 8080, 6836, 203, 8688, 6196, 11082, 8418, 4159, 10065, 9518, 10849, 3548, 7517, 12117, 12062, 5318, 2206, 8745, 10125, 946, 4027, 11859, 3755, 4930, 334, 9639, 1200, 11752, 9867, 4148, 9773, 426, 3605, 6899, 11297, 1478, 8646, 9937, 4138, 9058, 10513, 1110, 1229, 333, 3792, 6196, 1018, 2759, 6198, 7834, 7356, 5865, 4891, 9753, 7980, 7374, 11477, 3977, 8122, 11368, 5604, 11705, 3119, 3373, 9551, 11358, 7787, 5378, 9668, 7671, 10048, 6177, 5341, 87, 11016, 6498, 11316, 10006, 9555, 11043, 3413, 11782, 6594, 2702, 2712, 8549, 8874, 10101, 1317, 2011, 8158, 11678, 9893]
    xof = KeccaXOF

    # def const_salt(x):
    #     return b"\xc5\xb4\x0c'p\xa32 \x9f\x89\xd5\xc4\xf1\x106\x0e\xe8\x8b1\x0fU\xc6\xc7\n\xf5\x01\xee8:|\xe4r\xdb\xbd>\xff\xa0V\xac\x97"
    # sig = sk.sign(message.encode(), randombytes=const_salt, xof=xof)

    int_header = 0x30 + 9  # log(n)
    header = int_header.to_bytes(1, "little")
    salt = b"""\xc5\xb4\x0c'p\xa32 \x9f\x89\xd5\xc4\xf1\x106\x0e\xe8\x8b1\x0fU\xc6\xc7\n\xf5\x01\xee8:|\xe4r\xdb\xbd>\xff\xa0V\xac\x97"""
    enc_s = compress(s1, sk.sig_bytelen - HEAD_LEN - SALT_LEN)
    sig = header + salt + enc_s

    return sk.verify(message.encode(), sig, xof=xof, pk=pk)


def test(n, iterations=500):
    # """A battery of tests."""
    # wrapper_test(test_fft, "FFT", n, iterations)
    # wrapper_test(test_ntt, "NTT", n, iterations)
    # # test_ntrugen is super slow, hence performed over a single iteration
    # wrapper_test(test_ntrugen, "NTRUGen", n, 1)
    # wrapper_test(test_ffnp, "ffNP", n, iterations)
    # # test_compress and test_signature are only performed
    # # for parameter sets that are defined.
    # if (n in Params):
    #     wrapper_test(test_compress, "Compress", n, iterations)
    #     wrapper_test(test_signature, "Signature", n, iterations)
    #     wrapper_test(test_sign_KAT, "Signature KATs", n, iterations)
    # print("")

    # # Simon Tests
    # if (n in Params):
    #     test_keygen_different_ntt(n, 1)
    #     test_signing_different_xof(n, iterations)
    #     test_verif_different_ntt(n, iterations)
    #     test_verif_different_xof(n, iterations)
    # print("")

    # test_hash_to_point(n)
    if (n in Params):
        test_simon(n)
    print("")


    # Run all the tests
if (__name__ == "__main__"):
    # print("Test Sig KATs       : ", end="")
    # print("OK" if (test_sign_KAT() is True) else "Not OK")

    # # wrapper_test(test_samplerz_simple, "SamplerZ", None, 100000)
    # wrapper_test(test_samplerz_KAT, "SamplerZ KATs", None, 1)
    # print("")

    for i in range(9, 10):
        n = (1 << i)
        it = 100
        print("Test battery for n = {n}".format(n=n))
        test(n, it)
