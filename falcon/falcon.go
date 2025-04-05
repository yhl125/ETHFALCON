// Copyright 2025 Renaud Dubois, ZKNOX. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in
// the LICENSE file.
package main
/*

#define DALGNAME falcon512int
#cgo CFLAGS: -I. -DALGNAME=falcon512int
#cgo LDFLAGS: -DALGNAME=falcon512int -L. -lfalcon



#include "nistfalcon/src/api.h"
#include "nistfalcon/src/fpr.h"
#include "nistfalcon/src/inner.h"
#include "nistfalcon/src/keygen.h"
#include "nistfalcon/src/nist.h"
#include "nistfalcon/src/nist.c"
#include "nistfalcon/src/rng.h"
#include "nistfalcon/src/shake.h"
#include "nistfalcon/src/sign.h"
#include "nistfalcon/src/vrfy.h"
#include "nistfalcon/src/rng.h"
#include "nistfalcon/src/katrng.h"
#include "nistfalcon/src/PQCgenKAT_sign.cs"
*/

import "C"

import (
	"fmt"
	"unsafe"
)

const (
	PublicKeySize = 897
	SecretKeySize = 1281
)

func GenerateKeypair() ([]byte, []byte, error) {
	pk := make([]byte, PublicKeySize)
	sk := make([]byte, SecretKeySize)

	ret := C.crypto_sign_keypair(
		(*C.uchar)(unsafe.Pointer(&pk[0])),
		(*C.uchar)(unsafe.Pointer(&sk[0])),
	)

	if ret != 0 {
		return nil, nil, fmt.Errorf("keypair generation failed: %d", int(ret))
	}

	return pk, sk, nil
}

func main() {
	pk, sk, err := GenerateKeypair()
	if err != nil {
		panic(err)
	}

	fmt.Printf("Public key: %x...\n", pk[:16])
	fmt.Printf("Secret key: %x...\n", sk[:16])
}