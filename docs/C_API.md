# C API for Autonomi

The Autonomi FFI bindings include a C-compatible API that can be used from any language that supports C FFI (C, C++, Go, etc.).

> **Note**: This is a low-level API generated directly from UniFFI bindings. It requires manual serialization/deserialization and careful memory management. For a more ergonomic experience, consider using the Swift or Kotlin bindings, or building a higher-level C wrapper for your use case.

> **Quick Start**: See working examples in [`examples/c/`](../examples/c/) with a Makefile for easy building.

## Overview

The C API is automatically generated as part of the Swift bindings generation process. UniFFI produces a C header file (`ant_ffiFFI.h`) that declares all the FFI functions and types needed to interact with the Autonomi library.

## Building from Source

### Prerequisites

**Rust toolchain:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**Protobuf compiler** (required by dependencies):
```bash
# macOS
brew install protobuf

# Debian/Ubuntu
sudo apt install protobuf-compiler

# Fedora
sudo dnf install protobuf-compiler
```

### Build Steps

```bash
# Clone the repository
git clone https://github.com/maidsafe/ant-ffi.git
cd ant-ffi/rust

# Build the library
cargo build --release -p ant-ffi

# Generate the C header
cargo run -p uniffi-bindgen-swift -- \
    target/release/libant_ffi.a \
    output/ \
    --headers \
    --modulemap \
    --module-name ant_ffiFFI
```

### Build Artifacts

After building, copy these files to your project:

| File | Location | Description |
|------|----------|-------------|
| `libant_ffi.a` | `rust/target/release/` | Static library |
| `ant_ffiFFI.h` | `rust/output/` | C header file |

Platform-specific library variants:

| Platform | Static Library | Dynamic Library |
|----------|----------------|-----------------|
| Linux | `libant_ffi.a` | `libant_ffi.so` |
| macOS | `libant_ffi.a` | `libant_ffi.dylib` |
| Windows | `ant_ffi.lib` | `ant_ffi.dll` |

## Integrating into Your Project

### Project Structure

```
your_project/
├── include/
│   └── ant_ffiFFI.h
├── lib/
│   └── libant_ffi.a
└── src/
    └── main.c
```

### Compiling

**Linux:**
```bash
gcc -o myapp src/main.c -Iinclude -Llib -lant_ffi -lpthread -ldl -lm
```

**macOS:**
```bash
clang -o myapp src/main.c -Iinclude -Llib -lant_ffi \
    -framework Security -framework SystemConfiguration -framework CoreFoundation \
    -liconv -lresolv
```

### CMake Example

```cmake
cmake_minimum_required(VERSION 3.10)
project(myapp)

add_executable(myapp src/main.c)
target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/include)

# Link the library (adjust for your platform)
if(APPLE)
    target_link_libraries(myapp
        ${CMAKE_SOURCE_DIR}/lib/libant_ffi.a
        "-framework Security"
        "-framework SystemConfiguration"
        "-framework CoreFoundation"
        iconv resolv)
else()
    target_link_libraries(myapp
        ${CMAKE_SOURCE_DIR}/lib/libant_ffi.a
        pthread dl m)
endif()
```

## Core Types

### RustBuffer

Used to pass byte arrays between C and Rust:

```c
typedef struct RustBuffer {
    uint64_t capacity;  // Allocated capacity
    uint64_t len;       // Actual data length
    uint8_t *data;      // Pointer to data
} RustBuffer;
```

### ForeignBytes

Used to pass read-only byte data to Rust:

```c
typedef struct ForeignBytes {
    int32_t len;
    const uint8_t *data;
} ForeignBytes;
```

### RustCallStatus

Error handling for FFI calls:

```c
typedef struct RustCallStatus {
    int8_t code;           // 0 = success, non-zero = error
    RustBuffer errorBuf;   // Error message (if code != 0)
} RustCallStatus;
```

## Function Patterns

### Synchronous Functions

Synchronous functions can be called directly:

```c
#include "ant_ffiFFI.h"

// Create a chunk from data
RustCallStatus status = {0};
RustBuffer data = /* your data */;
void *chunk = uniffi_ant_ffi_fn_constructor_chunk_new(data, &status);

if (status.code != 0) {
    // Handle error - status.errorBuf contains error message
}

// Get chunk value
RustBuffer value = uniffi_ant_ffi_fn_method_chunk_value(chunk, &status);

// Free the chunk when done
uniffi_ant_ffi_fn_free_chunk(chunk, &status);
```

### Async Functions

Async functions return a future handle and use callbacks:

```c
// Callback type for async completion
typedef void (*UniffiRustFutureContinuationCallback)(uint64_t callback_data, int8_t poll_result);

// Example: Async data retrieval
void my_callback(uint64_t callback_data, int8_t poll_result) {
    if (poll_result == 0) {
        // Future is ready - get the result
        RustCallStatus status = {0};
        RustBuffer result = ffi_ant_ffi_rust_future_complete_rust_buffer(
            callback_data,  // This is actually the future handle
            &status
        );

        // Process result...

        // Free the future
        ffi_ant_ffi_rust_future_free_rust_buffer(callback_data);
    } else {
        // Poll again or handle cancellation
    }
}

// Start async operation
uint64_t future_handle = uniffi_ant_ffi_fn_method_client_data_get_public(
    client_ptr,
    address_hex_buffer
);

// Poll the future with callback
ffi_ant_ffi_rust_future_poll_rust_buffer(
    future_handle,
    my_callback,
    future_handle  // Pass handle as callback_data
);
```

### Async Future API

For each return type, these functions are available:

```c
// Poll the future - calls callback when ready
void ffi_ant_ffi_rust_future_poll_<type>(
    uint64_t handle,
    UniffiRustFutureContinuationCallback callback,
    uint64_t callback_data
);

// Cancel the future
void ffi_ant_ffi_rust_future_cancel_<type>(uint64_t handle);

// Get the result (call only when poll indicates ready)
<type> ffi_ant_ffi_rust_future_complete_<type>(
    uint64_t handle,
    RustCallStatus *out_status
);

// Free the future handle
void ffi_ant_ffi_rust_future_free_<type>(uint64_t handle);
```

Where `<type>` can be: `u8`, `i8`, `u16`, `i16`, `u32`, `i32`, `u64`, `i64`, `f32`, `f64`, `pointer`, `rust_buffer`, `void`.

## Memory Management

### RustBuffer Allocation

```c
// Allocate a RustBuffer from bytes
RustCallStatus status = {0};
ForeignBytes bytes = { .len = data_len, .data = data_ptr };
RustBuffer buffer = ffi_ant_ffi_rustbuffer_from_bytes(bytes, &status);

// Free a RustBuffer when done
ffi_ant_ffi_rustbuffer_free(buffer, &status);
```

### Object Lifecycle

Objects returned as `void*` pointers must be freed:

```c
// Clone an object (increment reference)
void *cloned = uniffi_ant_ffi_fn_clone_client(client_ptr, &status);

// Free an object (decrement reference)
uniffi_ant_ffi_fn_free_client(client_ptr, &status);
```

## Available Functions

### Client Operations

| Function | Description |
|----------|-------------|
| `uniffi_ant_ffi_fn_constructor_client_init` | Initialize client (async) |
| `uniffi_ant_ffi_fn_method_client_data_get_public` | Get public data (async) |
| `uniffi_ant_ffi_fn_method_client_data_put_public` | Store public data (async) |
| `uniffi_ant_ffi_fn_method_client_chunk_get` | Get a chunk (async) |
| `uniffi_ant_ffi_fn_method_client_chunk_put` | Store a chunk (async) |

### Encryption

| Function | Description |
|----------|-------------|
| `uniffi_ant_ffi_fn_func_encrypt` | Encrypt data (sync) |
| `uniffi_ant_ffi_fn_func_decrypt` | Decrypt data (sync) |

### Key Derivation

| Function | Description |
|----------|-------------|
| `uniffi_ant_ffi_fn_constructor_blsmnemonic_random` | Generate random mnemonic |
| `uniffi_ant_ffi_fn_constructor_blsmnemonic_from_phrase` | Parse mnemonic phrase |

For a complete list of functions, see the generated `ant_ffiFFI.h` header file.

## UniFFI Serialization Format

**Important**: UniFFI uses a specific serialization format for data types. For `Vec<u8>` (byte arrays), data must be serialized as:
- 4-byte **big-endian** length prefix
- Followed by raw bytes

```c
// Serialize bytes for UniFFI
size_t len = strlen(data);
uint8_t *buf = malloc(4 + len);
buf[0] = (len >> 24) & 0xFF;  // Big-endian length
buf[1] = (len >> 16) & 0xFF;
buf[2] = (len >> 8) & 0xFF;
buf[3] = len & 0xFF;
memcpy(buf + 4, data, len);

ForeignBytes fb = { .len = 4 + len, .data = buf };
RustBuffer input = ffi_ant_ffi_rustbuffer_from_bytes(fb, &status);
free(buf);
```

When reading results, skip the 4-byte length prefix to get the actual data.

## Example: Self-Encryption

> **See also**: [`examples/c/self_encryption.c`](../examples/c/self_encryption.c) for a complete working example with Makefile.

```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ant_ffiFFI.h"

int main() {
    RustCallStatus status = {0};
    const char *msg = "Hello from C! This is a test of self-encryption.";
    size_t len = strlen(msg);

    // Serialize: 4-byte big-endian length + data (UniFFI format)
    uint8_t *buf = malloc(4 + len);
    buf[0] = buf[1] = buf[2] = 0; buf[3] = (uint8_t)len;
    memcpy(buf + 4, msg, len);
    ForeignBytes fb = { .len = 4 + len, .data = buf };
    RustBuffer input = ffi_ant_ffi_rustbuffer_from_bytes(fb, &status);
    free(buf);

    // Encrypt -> Decrypt
    RustBuffer enc = uniffi_ant_ffi_fn_func_encrypt(input, &status);
    if (status.code) { printf("Encrypt failed\n"); return 1; }

    status = (RustCallStatus){0};
    RustBuffer dec = uniffi_ant_ffi_fn_func_decrypt(enc, &status);
    if (status.code) { printf("Decrypt failed\n"); return 1; }

    // Verify (skip 4-byte length prefix)
    int ok = (dec.data[3] == len && memcmp(dec.data + 4, msg, len) == 0);
    printf("Original:  %s\nDecrypted: %.*s\n%s\n", msg, (int)len, dec.data + 4, ok ? "SUCCESS!" : "FAILED!");

    ffi_ant_ffi_rustbuffer_free(dec, &status);
    return !ok;
}
```

## Thread Safety

- All FFI functions are thread-safe
- Objects can be shared across threads (they use internal synchronization)
- Async futures should be polled from a consistent thread or with proper synchronization

## Error Handling

Always check `RustCallStatus.code` after each call:

```c
RustCallStatus status = {0};
void *result = some_ffi_function(&status);

if (status.code != 0) {
    // Error occurred
    if (status.errorBuf.data != NULL) {
        printf("Error: %.*s\n", (int)status.errorBuf.len, status.errorBuf.data);
        ffi_ant_ffi_rustbuffer_free(status.errorBuf, &(RustCallStatus){0});
    }
}
```

## Limitations

1. **Async complexity**: The callback-based async API requires careful state management
2. **No high-level wrappers**: The C API is low-level; consider writing helper functions for your use case
3. **Manual memory management**: All `RustBuffer` and object pointers must be explicitly freed
