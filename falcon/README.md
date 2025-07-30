# Bindings Go and javascript

This repository provides binding in Go and javascript of the NIST source files.


## Javascript bindings

### Install Emscripten (emsdk)
Emscripten is a complete compiler toolchain to WebAssembly, using LLVM. It is required to execute the make ```js target```.

 ```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
 ```


### Compile and test

 ```bash
 make js
 node test_falcon.js
 ```
An example of use (key generation, sign and verify) is provided in test_example.js

## Go bindings

## Go bindings

### Auto-architecture detection
This package now automatically detects your system architecture and builds accordingly:
- macOS: ARM64 (Apple Silicon) and x86_64 (Intel) supported
- Linux: ARM64 and x86_64 supported

### Building

Auto-detect current architecture (recommended):
```bash
make go
```

For specific architectures:
```bash
make go-arm64     # Force ARM64 build
make go-x86_64    # Force x86_64 build
```

For macOS universal binary (both architectures):
```bash
make go-universal-mac
```

### Testing
```bash
go run falcon.go
```

### Using in your project
```bash
go get github.com/yhl125/ETHFALCON/falcon@latest
```

### Available commands
```bash
make help  # Shows all available targets and current system info
make clean # Cleans build artifacts
```