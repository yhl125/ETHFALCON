SHELL := /bin/bash

go:
 #clean previous build
	cd build;rm -f *.o *.a;
 #build C library
	cd nistfalcon;rm -rf build;mkdir build;
	cd nistfalcon/src;\
	gcc -c -O3 -fPIC -DALGNAME=falcon512int *.c;\
	ar rcs libfalcon.a *.o; \
	mv *.o ../build;mv *.a ../build;
 #build and run go library
	go run falcon.go

js:
#clean previous build
	cd build;rm -f *.o *.a;
 #build C library, first line is the path to your emsdk environment
	. $(HOME)/github/emsdk/emsdk_env.sh && \
	cd nistfalcon;rm -rf build;mkdir build;\
	cd src;\
emcc \
  codec.c common.c epervier16.c fft.c fpr.c keygen.c katrng.c nist.c rng.c shake.c sign.c vrfy.c \
  -I. \
  -s WASM=1 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME="Module" \
  -s EXPORTED_FUNCTIONS='["_crypto_sign_keypair", "_crypto_sign", "_crypto_sign_open", "_malloc", "_free"]' \
  -s EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -O3 \
  -o falcon.js;mv falcon.js  ../..; mv falcon.wasm ../..

