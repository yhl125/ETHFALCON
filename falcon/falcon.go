package main

/*
#cgo CFLAGS: -I${SRCDIR}/nistfalcon/src
#cgo LDFLAGS: -L${SRCDIR}/nistfalcon/build 
#cgo LDFLAGS: -lfalcon

#include <stdlib.h>
#include "api.h"

// Wrapper for crypto_sign_keypair

*/
import "C"

import (
	"fmt"
	"unsafe"
)

const (
	PublicKeySize = 897  // Adjust if api.h specifies differently
	SecretKeySize = 1281 // Adjust if api.h specifies differently
)

func GenerateKeypair() ([]byte, []byte, error) {
	var pk [PublicKeySize]C.uchar
	var sk [SecretKeySize]C.uchar

	ret := C.crypto_sign_keypair(&pk[0], &sk[0])
	if ret != 0 {
		return nil, nil, fmt.Errorf("keypair generation failed: %d", int(ret))
	}

	pkBytes := C.GoBytes(unsafe.Pointer(&pk[0]), C.int(PublicKeySize))
	skBytes := C.GoBytes(unsafe.Pointer(&sk[0]), C.int(SecretKeySize))

	return pkBytes, skBytes, nil
}



func main() {
	pk, sk, err := GenerateKeypair()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	fmt.Printf("Public Key (first 10 bytes): %x\n", pk[:10])
	fmt.Printf("Secret Key (first 10 bytes): %x\n", sk[:10])
}