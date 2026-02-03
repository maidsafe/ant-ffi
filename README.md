# Autonomi FFI Bindings

Multi-platform bindings for the Autonomi network.

[![JitPack](https://jitpack.io/v/maidsafe/ant-ffi.svg)](https://jitpack.io/#maidsafe/ant-ffi)

| Platform | Language | Status |
|----------|----------|--------|
| Android | Kotlin/Java | Stable |
| iOS/macOS | Swift | Stable |
| Go | Go | Available |
| C/C++ | C | Available |

## Android

### Installation

Add JitPack repository to your `settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        maven { url = uri("https://jitpack.io") }
    }
}
```

Add the dependency to your module's `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.github.maidsafe:ant-ffi:v0.0.15")
    implementation("net.java.dev.jna:jna:5.15.0@aar")
}
```

> **Note:** JNA AAR must be added explicitly for Android native library support.

### Quick Start

```kotlin
import uniffi.ant_ffi.*

// Initialize client
val client = Client.init()

// Create a wallet
val network = Network.custom(
    rpcUrl = "https://your-rpc-url",
    paymentTokenAddress = "0x...",
    dataPaymentsAddress = "0x..."
)
val wallet = Wallet.fromPrivateKey(network, "your-private-key")

// Upload data
val result = client.dataPutPublic(
    data = "Hello Autonomi!".toByteArray(),
    payment = PaymentOption.WalletPayment(wallet)
)
println("Uploaded to: ${result.address}")

// Download data
val data = client.dataGetPublic(result.address)
println("Downloaded: ${String(data)}")
```

### Usage Examples

For comprehensive usage examples, see the test files in [`android/core/src/test/java/com/maidsafe/autonomi/core/`](android/core/src/test/java/com/maidsafe/autonomi/core/):

| Test File | Features Covered |
|-----------|------------------|
| `RegisterNetworkTest.kt` | Register create, read, update, history |
| `PointerNetworkTest.kt` | Pointer create, get, update, existence check |
| `ScratchpadNetworkTest.kt` | Scratchpad create, decrypt, update |
| `FileNetworkTest.kt` | Private/public data, file upload/download, archives |
| `KeyDerivationTest.kt` | BLS key derivation from mnemonics |
| `ArchiveTest.kt` | Archive and metadata operations |

## iOS

### Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/maidsafe/ant-ffi.git", from: "0.0.15")
]
```

Then add `Autonomi` to your target dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["Autonomi"]
)
```

> **Note:** The XCFramework is pre-built and downloaded automatically via Swift Package Manager. No Rust toolchain required.

### Quick Start

```swift
import Autonomi

// Encrypt and decrypt data locally
let data: [UInt8] = Array("Hello, Autonomi!".utf8)
let encrypted = try encrypt(data)
let decrypted = try decrypt(encrypted)
print(String(bytes: decrypted, encoding: .utf8)!)

// Initialize client (when network is available)
let client = try await Client.init()

// Create a wallet
let network = try Network.custom(
    rpcUrl: "https://your-rpc-url",
    paymentTokenAddress: "0x...",
    dataPaymentsAddress: "0x..."
)
let wallet = try Wallet.fromPrivateKey(network: network, privateKey: "your-private-key")

// Upload data
let result = try await client.dataPutPublic(
    data: Data("Hello Autonomi!".utf8),
    payment: .walletPayment(wallet)
)
print("Uploaded to: \(result.address)")

// Download data
let downloaded = try await client.dataGetPublic(address: result.address)
print("Downloaded: \(String(data: downloaded, encoding: .utf8)!)")
```

### Usage Examples

For usage examples, see the test files in [`apple/Tests/AutonomiTests/`](apple/Tests/AutonomiTests/).

For a complete example app, see the **[iOS Example Project](examples/ios/)**.

## Go

Go bindings using CGO to call the native Rust FFI library.

### Prerequisites

- Go 1.21 or later
- CGO enabled (`CGO_ENABLED=1`)
- C compiler (GCC/Clang on Linux/macOS, MinGW on Windows)
- The native `ant_ffi` shared library built from source

### Quick Start

```go
package main

import (
    "context"
    "fmt"
    "github.com/maidsafe/ant-ffi/go/antffi"
)

func main() {
    // Encrypt and decrypt data locally
    data := []byte("Hello, Autonomi!")
    encrypted, _ := antffi.Encrypt(data)
    decrypted, _ := antffi.Decrypt(encrypted)
    fmt.Println(string(decrypted)) // "Hello, Autonomi!"

    // Initialize client (when network is available)
    ctx := context.Background()
    client, _ := antffi.NewClientLocal(ctx)
    defer client.Free()

    // Create a wallet
    network, _ := antffi.NewNetwork(true) // local network
    defer network.Free()
    wallet, _ := antffi.NewWalletFromPrivateKey(network, "your-private-key")
    defer wallet.Free()

    // Upload data
    payment := &antffi.PaymentOption{Wallet: wallet}
    result, _ := client.DataPutPublic(ctx, []byte("Hello Autonomi!"), payment)
    fmt.Printf("Uploaded to: %s\n", result.Address)

    // Download data
    downloaded, _ := client.DataGetPublic(ctx, result.Address)
    fmt.Printf("Downloaded: %s\n", string(downloaded))
}
```

### Usage Examples

For comprehensive usage examples, see the test files in [`go/antffi_test/`](go/antffi_test/):

| Test File | Features Covered |
|-----------|------------------|
| `client_test.go` | Client init, data upload/download, pointers, wallets |
| `keys_test.go` | Secret keys, public keys, main secret keys, key derivation |
| `data_test.go` | Chunks, addresses, data map operations |
| `selfencryption_test.go` | Self-encryption, decryption, byte round-trips |

## C/C++

A C-compatible API is available for integration with C, C++, and any language that supports C FFI.

### Quick Start

```c
#include "ant_ffiFFI.h"

int main() {
    RustCallStatus status = {0};

    // Encrypt data
    const char *message = "Hello, Autonomi!";
    ForeignBytes input = { .len = strlen(message), .data = (const uint8_t *)message };
    RustBuffer input_buffer = ffi_ant_ffi_rustbuffer_from_bytes(input, &status);

    RustBuffer encrypted = uniffi_ant_ffi_fn_func_encrypt(input_buffer, &status);
    RustBuffer decrypted = uniffi_ant_ffi_fn_func_decrypt(encrypted, &status);

    printf("Decrypted: %.*s\n", (int)decrypted.len, decrypted.data);

    // Cleanup
    ffi_ant_ffi_rustbuffer_free(decrypted, &status);
    return 0;
}
```

For full documentation including async operations, memory management, and build instructions, see **[C API Documentation](docs/C_API.md)**.

## Available APIs

- **Data**: Upload and download public/private data
- **Registers**: Mutable versioned storage
- **Vaults**: Encrypted user data storage
- **Pointers**: Mutable references to data
- **Scratchpads**: Encrypted mutable data with versioning
- **GraphEntry**: Graph-based data structures

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
