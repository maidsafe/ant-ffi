# Go Bindings Plan for ant-ffi

## Project Structure

```
go/
├── antffi/
│   ├── antffi.go          # Package declaration, cgo setup, library loading
│   ├── types.go           # RustBuffer, ForeignBytes, RustCallStatus structs
│   ├── helpers.go         # UniFFI serialization helpers
│   ├── errors.go          # Error types
│   ├── selfencryption.go  # Encrypt/Decrypt functions
│   ├── keys.go            # SecretKey, PublicKey
│   ├── keyderivation.go   # DerivationIndex, Signature, MainSecretKey, etc.
│   ├── data.go            # Chunk, ChunkAddress, DataAddress, DataMapChunk
│   ├── archive.go         # Metadata, ArchiveAddress, PublicArchive, PrivateArchive
│   ├── pointer.go         # PointerAddress, PointerTarget, NetworkPointer
│   ├── scratchpad.go      # ScratchpadAddress, Scratchpad
│   ├── register.go        # RegisterAddress, RegisterHelpers
│   ├── graphentry.go      # GraphEntryAddress, GraphEntry
│   ├── vault.go           # VaultSecretKey, UserData
│   ├── network.go         # Network configuration
│   ├── wallet.go          # Wallet with async balance methods
│   ├── client.go          # Client with all async operations
│   └── async.go           # Async future polling infrastructure
├── antffi_test/
│   ├── selfencryption_test.go
│   ├── keys_test.go
│   ├── data_test.go
│   ├── client_test.go
│   └── integration_test.go
├── go.mod
└── go.sum
```

## CGO Setup (antffi.go)

```go
package antffi

/*
#cgo CFLAGS: -I${SRCDIR}/../rust/target/release
#cgo LDFLAGS: -L${SRCDIR}/../rust/target/release -lant_ffi

#include <stdint.h>
#include <stdlib.h>

// RustBuffer structure
typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

// ForeignBytes structure
typedef struct {
    int32_t len;
    uint8_t* data;
} ForeignBytes;

// RustCallStatus structure
typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// Buffer management
extern RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus* status);
extern void ffi_ant_ffi_rustbuffer_free(RustBuffer buf, RustCallStatus* status);

// Self-encryption
extern RustBuffer uniffi_ant_ffi_fn_func_encrypt(RustBuffer data, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_func_decrypt(RustBuffer data, RustCallStatus* status);

// Keys
extern void* uniffi_ant_ffi_fn_constructor_secretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_secretkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_secretkey_to_hex(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_secretkey_public_key(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_secretkey(void* ptr, RustCallStatus* status);

// ... more declarations

// Async future polling
typedef void (*UniffiRustFutureContinuationCallback)(uint64_t, int8_t);
extern void ffi_ant_ffi_rust_future_poll_pointer(uint64_t handle, UniffiRustFutureContinuationCallback cb, uint64_t data);
extern void* ffi_ant_ffi_rust_future_complete_pointer(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_free_pointer(uint64_t handle);

// ... more async declarations
*/
import "C"
```

## Key Patterns

### 1. Handle Wrapper with Destructor

```go
// SecretKey wraps a native secret key handle
type SecretKey struct {
    handle unsafe.Pointer
    freed  bool
}

// Free releases the native resources
func (s *SecretKey) Free() {
    if s.freed || s.handle == nil {
        return
    }
    var status C.RustCallStatus
    C.uniffi_ant_ffi_fn_free_secretkey(s.handle, &status)
    s.freed = true
}

// Use runtime.SetFinalizer for automatic cleanup
func newSecretKey(handle unsafe.Pointer) *SecretKey {
    sk := &SecretKey{handle: handle}
    runtime.SetFinalizer(sk, (*SecretKey).Free)
    return sk
}
```

### 2. RustBuffer Helpers

```go
func toRustBuffer(data []byte) C.RustBuffer {
    if len(data) == 0 {
        return C.RustBuffer{}
    }

    // Serialize with 4-byte big-endian length prefix (UniFFI format)
    buf := make([]byte, 4+len(data))
    binary.BigEndian.PutUint32(buf[0:4], uint32(len(data)))
    copy(buf[4:], data)

    fb := C.ForeignBytes{
        len:  C.int32_t(len(buf)),
        data: (*C.uint8_t)(unsafe.Pointer(&buf[0])),
    }

    var status C.RustCallStatus
    return C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
}

func fromRustBuffer(buf C.RustBuffer, free bool) []byte {
    if buf.len == 0 {
        return nil
    }

    data := C.GoBytes(unsafe.Pointer(buf.data), C.int(buf.len))

    if free {
        var status C.RustCallStatus
        C.ffi_ant_ffi_rustbuffer_free(buf, &status)
    }

    // Deserialize - skip 4-byte length prefix
    if len(data) < 4 {
        return data
    }
    return data[4:]
}
```

### 3. Async Future Polling (Go channels)

```go
// FutureResult holds the result of an async operation
type FutureResult struct {
    Pointer unsafe.Pointer
    Buffer  C.RustBuffer
    Error   error
}

// pollPointerFuture polls a pointer-returning future
func pollPointerFuture(futureHandle uint64) (unsafe.Pointer, error) {
    done := make(chan struct{})
    var ready int8

    callback := func(data uint64, pollResult int8) {
        ready = pollResult
        close(done)
    }

    // Register callback and poll
    callbackPtr := registerCallback(callback)
    C.ffi_ant_ffi_rust_future_poll_pointer(C.uint64_t(futureHandle), callbackPtr, 0)

    // Wait for completion
    <-done

    if ready != 0 {
        // Poll again - not ready yet
        return pollPointerFuture(futureHandle)
    }

    // Complete the future
    var status C.RustCallStatus
    result := C.ffi_ant_ffi_rust_future_complete_pointer(C.uint64_t(futureHandle), &status)
    C.ffi_ant_ffi_rust_future_free_pointer(C.uint64_t(futureHandle))

    if status.code != 0 {
        return nil, parseError(status)
    }

    return result, nil
}
```

### 4. Context-based Cancellation

```go
func (c *Client) DataPutPublicCtx(ctx context.Context, data []byte, wallet *Wallet) (*DataAddress, error) {
    if c.freed {
        return nil, ErrDisposed
    }

    dataBuffer := toRustBuffer(data)
    defer freeRustBuffer(dataBuffer)

    futureHandle := C.uniffi_ant_ffi_fn_method_client_data_put_public(c.handle, dataBuffer, wallet.handle)

    resultCh := make(chan *FutureResult, 1)
    go func() {
        ptr, err := pollPointerFuture(uint64(futureHandle))
        resultCh <- &FutureResult{Pointer: ptr, Error: err}
    }()

    select {
    case <-ctx.Done():
        C.ffi_ant_ffi_rust_future_cancel_pointer(futureHandle)
        return nil, ctx.Err()
    case result := <-resultCh:
        if result.Error != nil {
            return nil, result.Error
        }
        return newDataAddress(result.Pointer), nil
    }
}
```

## Implementation Order

1. **Core Infrastructure** (types.go, helpers.go, errors.go, antffi.go)
2. **Sync Operations** (selfencryption.go, keys.go, keyderivation.go, data.go)
3. **More Sync Types** (archive.go, pointer.go, scratchpad.go, register.go, graphentry.go, vault.go)
4. **Async Infrastructure** (async.go)
5. **Network/Wallet/Client** (network.go, wallet.go, client.go)
6. **Tests**

## API Examples

```go
package main

import (
    "context"
    "fmt"
    "github.com/maidsafe/ant-ffi/go/antffi"
)

func main() {
    // Self-encryption
    data := []byte("Hello from Go!")
    encrypted, _ := antffi.Encrypt(data)
    decrypted, _ := antffi.Decrypt(encrypted)

    // Keys
    sk := antffi.NewSecretKey()
    defer sk.Free()
    pk := sk.PublicKey()
    defer pk.Free()

    // Network client (async with context)
    ctx := context.Background()
    network := antffi.NewNetwork(true) // local
    defer network.Free()

    client, _ := antffi.NewClientCtx(ctx, network)
    defer client.Free()

    wallet := antffi.NewWalletFromPrivateKey(network, "0x...")
    defer wallet.Free()

    // Upload data
    address, _ := client.DataPutPublicCtx(ctx, []byte("Hello!"), wallet)
    fmt.Printf("Uploaded to: %s\n", address.ToHex())

    // Download data
    retrieved, _ := client.DataGetPublicCtx(ctx, address)
    fmt.Printf("Retrieved: %s\n", string(retrieved))

    // Private data with DataMapChunk
    dataMap, _ := client.DataPutCtx(ctx, []byte("Private data"), wallet)
    hex := dataMap.ToHex() // Save this!

    // Later: restore and download
    restoredMap := antffi.DataMapChunkFromHex(hex)
    privateData, _ := client.DataGetCtx(ctx, restoredMap)
}
```

## Build Instructions

```bash
# Build the Rust library first
cd rust
cargo build --release

# Build and test Go bindings
cd ../go
go build ./...
go test ./...

# Run with CGO
CGO_ENABLED=1 go run example/main.go
```

## Platform-Specific Notes

- **Windows**: Use `.dll` extension, may need MinGW or MSVC
- **Linux**: Use `.so` extension, standard gcc
- **macOS**: Use `.dylib` extension, standard clang

Library search paths will need to be configured appropriately for each platform.
