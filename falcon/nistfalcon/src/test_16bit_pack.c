#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "inner.h"  // <- gives access to Zf(modq_encode16) and related

#define LOGN 4
#define N (1 << LOGN)

int main(void) {
    uint16_t h[N] = {
        1, 2, 3, 4, 12288, 0, 300, 12200,
        111, 222, 333, 444, 555, 666, 777, 888
    };

    printf("Initial %u bytes:\n", N);
    for (size_t i = 0; i < N; i++) {
        printf("%04X ", h[i]);
    }
    printf("\n");


    uint8_t buf[32];
    size_t encoded_len = Zf(modq_encode16)(buf, sizeof(buf), h, LOGN);

    printf("Encoded %lu bytes:\n", encoded_len);
    for (size_t i = 0; i < encoded_len; i++) {
        printf("%02X ", buf[i]);
    }
    printf("\n");


    uint16_t back[N];
    Zf(modq_decode16(back, LOGN, buf, 32));
    
    printf("Decoded %u bytes:\n", N);
    for (size_t i = 0; i < N; i++) {
        printf("%04X ", back[i]);
    }
    printf("\n");

    return 0;
}
