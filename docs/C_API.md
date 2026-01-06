# C API for Autonomi

The Autonomi FFI bindings include a C-compatible API that can be used from any language that supports C FFI (C, C++, Go, etc.).

## Overview

The C API is automatically generated as part of the Swift bindings generation process. UniFFI produces a C header file (`ant_ffiFFI.h`) that declares all the FFI functions and types needed to interact with the Autonomi library.

## Generating the C Header

### Prerequisites

- Rust toolchain (stable)
- The ant-ffi library built

### Build Steps

```bash
# Clone the repository
git clone https://github.com/maidsafe/ant-ffi.git
cd ant-ffi/rust

# Build the library (release mode recommended)
cargo build --release -p ant-ffi

# Generate the C header
cargo run -p uniffi-bindgen-swift -- \
    target/release/libant_ffi.a \
    output/ \
    --headers \
    --modulemap \
    --module-name ant_ffiFFI
```

This produces:
- `output/ant_ffiFFI.h` - The C header file
- `output/ant_ffi.modulemap` - Swift module map (can be ignored for C usage)

## Library Files

The build produces platform-specific library files:

| Platform | Static Library | Dynamic Library |
|----------|----------------|-----------------|
| Linux | `libant_ffi.a` | `libant_ffi.so` |
| macOS | `libant_ffi.a` | `libant_ffi.dylib` |
| Windows | `ant_ffi.lib` | `ant_ffi.dll` |

Location: `rust/target/release/`

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

## Linking

### Linux/macOS

```bash
# Static linking
gcc -o myapp myapp.c -L/path/to/lib -lant_ffi -lpthread -ldl -lm

# Dynamic linking
gcc -o myapp myapp.c -L/path/to/lib -lant_ffi -Wl,-rpath,/path/to/lib
```

### CMake Example

```cmake
cmake_minimum_required(VERSION 3.10)
project(myapp)

add_executable(myapp main.c)

# Include the header
target_include_directories(myapp PRIVATE /path/to/ant_ffiFFI.h)

# Link the library
target_link_libraries(myapp /path/to/libant_ffi.a pthread dl m)
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

## Example: Simple Encryption

```c
#include <stdio.h>
#include <string.h>
#include "ant_ffiFFI.h"

int main() {
    RustCallStatus status = {0};

    // Prepare data to encrypt
    const char *message = "Hello, Autonomi!";
    ForeignBytes input = {
        .len = strlen(message),
        .data = (const uint8_t *)message
    };
    RustBuffer input_buffer = ffi_ant_ffi_rustbuffer_from_bytes(input, &status);

    // Encrypt
    RustBuffer encrypted = uniffi_ant_ffi_fn_func_encrypt(input_buffer, &status);
    if (status.code != 0) {
        printf("Encryption failed\n");
        return 1;
    }

    // Decrypt
    RustBuffer decrypted = uniffi_ant_ffi_fn_func_decrypt(encrypted, &status);
    if (status.code != 0) {
        printf("Decryption failed\n");
        return 1;
    }

    printf("Decrypted: %.*s\n", (int)decrypted.len, decrypted.data);

    // Cleanup
    ffi_ant_ffi_rustbuffer_free(input_buffer, &status);
    ffi_ant_ffi_rustbuffer_free(encrypted, &status);
    ffi_ant_ffi_rustbuffer_free(decrypted, &status);

    return 0;
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
