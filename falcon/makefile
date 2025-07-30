SHELL := /bin/bash

# Detect current architecture and OS
ARCH := $(shell uname -m)
OS := $(shell uname -s)

ifeq ($(ARCH),x86_64)
    GCC_ARCH := x86_64
else ifeq ($(ARCH),arm64)
    GCC_ARCH := arm64
else ifeq ($(ARCH),aarch64)
    GCC_ARCH := arm64
else
    GCC_ARCH := $(ARCH)
endif

# Set GCC flags based on OS
ifeq ($(OS),Darwin)
    GCC_FLAGS := -arch $(GCC_ARCH)
else
    GCC_FLAGS := 
endif

go:
	rm -f go.mod
 #clean previous build
	cd nistfalcon;rm -rf build;mkdir build;
 #build C library for current architecture
	cd nistfalcon/src;\
	echo "Building for OS: $(OS), Architecture: $(GCC_ARCH)";\
	gcc -c -O3 -fPIC $(GCC_FLAGS) -DALGNAME=falcon512int *.c;\
	ar rcs libfalcon.a *.o; \
	mv *.o ../build;mv *.a ../build;
 #build and run go library
	go mod init github.com/yhl125/ETHFALCON/falcon;\
	go mod tidy;\
	echo "Built successfully for $(OS)/$(GCC_ARCH)";\
	echo "remember to type <go get github.com/yhl125/ETHFALCON/falcon@latest> in go-ethereum after modification of the go.mod"

js:
#clean previous build
	cd build;rm -f *.o *.a;
 #build C library, first line is the path to your emsdk environment
	. $(HOME)/github/emsdk/emsdk_env.sh && \
	cd nistfalcon/src;\
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

# Force build for specific architecture (optional)
go-arm64:
	$(MAKE) go GCC_ARCH=arm64 GCC_FLAGS="-arch arm64"

go-x86_64:
	$(MAKE) go GCC_ARCH=x86_64 GCC_FLAGS="-arch x86_64"

# Universal binary for macOS (both architectures)
go-universal-mac:
	rm -f go.mod
	cd nistfalcon;rm -rf build;mkdir build;
	cd nistfalcon/src;\
	echo "Building universal binary for macOS (arm64 + x86_64)";\
	gcc -c -O3 -fPIC -arch arm64 -arch x86_64 -DALGNAME=falcon512int *.c;\
	ar rcs libfalcon.a *.o; \
	mv *.o ../build;mv *.a ../build;
	go mod init github.com/yhl125/ETHFALCON/falcon;\
	go mod tidy;\
	echo "Built universal binary for macOS";

# Help target to show available commands
help:
	@echo "Available targets:"
	@echo "  go                  - Build for current platform (auto-detects architecture)"
	@echo "  go-arm64           - Force build for ARM64 architecture"
	@echo "  go-x86_64          - Force build for x86_64 architecture"
	@echo "  go-universal-mac   - Build universal binary for macOS (both architectures)"
	@echo "  js                 - Build JavaScript/WASM version"
	@echo "  clean              - Clean build artifacts"
	@echo "  help               - Show this help message"
	@echo ""
	@echo "Current system: $(OS)/$(GCC_ARCH)"
	@echo "For publishing to Go modules, use 'go' target (recommended)"

clean:
	rm -rf nistfalcon/build
	rm -f go.mod go.sum
	rm -f falcon.js falcon.wasm

.PHONY: help clean go go-arm64 go-x86_64 go-universal-mac js

# Default target
.DEFAULT_GOAL := help
