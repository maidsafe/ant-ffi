# Autonomi FFI Bindings

Multi-platform bindings for the Autonomi network.

[![JitPack](https://jitpack.io/v/maidsafe/ant-ffi.svg)](https://jitpack.io/#maidsafe/ant-ffi)

| Platform | Language | Status |
|----------|----------|--------|
| Android | Kotlin/Java | Stable |
| iOS/macOS | Swift | Stable |
| C#/.NET | C# | Available |
| Lua | LuaJIT | Available |
| Dart/Flutter | Dart | Available |
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

## C# / .NET

C# bindings for the Autonomi network, targeting .NET 8.0+.

### Prerequisites

- .NET 8.0 SDK or later
- The native `ant_ffi` shared library for your platform (place it alongside your application binary)

### Quick Start

```csharp
using AntFfi;

// Encrypt and decrypt data locally
var encrypted = SelfEncryption.Encrypt("Hello, Autonomi!");
var decrypted = SelfEncryption.DecryptToString(encrypted);
Console.WriteLine(decrypted); // "Hello, Autonomi!"

// Initialize client (when network is available)
using var network = Network.Create(isLocal: true);
using var client = await Client.InitAsync(network);

// Create a wallet
using var wallet = Wallet.FromPrivateKey(network, "your-private-key");

// Upload data
var data = System.Text.Encoding.UTF8.GetBytes("Hello Autonomi!");
var address = await client.DataPutPublicAsync(data, wallet);
Console.WriteLine($"Uploaded to: {address.ToHex()}");

// Download data
var downloaded = await client.DataGetPublicAsync(address);
Console.WriteLine($"Downloaded: {System.Text.Encoding.UTF8.GetString(downloaded)}");
```

### Usage Examples

For comprehensive usage examples, see the test files in [`csharp/AntFfi.Tests/`](csharp/AntFfi.Tests/):

| Test File | Features Covered |
|-----------|------------------|
| `ClientTests.cs` | Client init, data upload/download, file operations, pointers |
| `DataTypeTests.cs` | Data types, chunk constants, address operations |
| `KeyTests.cs` | Secret keys, public keys, main secret keys, key derivation |
| `SelfEncryptionTests.cs` | Self-encryption, decryption, string round-trips |

## Lua (LuaJIT)

Lua bindings using LuaJIT FFI for the Autonomi network.

### Prerequisites

- **LuaJIT 2.1+** (or Lua 5.1+ with cffi-lua)
- **Rust toolchain** (for building native libraries)
- **C compiler** (GCC/MinGW on Windows, gcc/clang on Linux/macOS)

### Building Native Libraries

The Lua bindings require two native libraries:

#### 1. Build `ant_ffi` (main library)

```bash
cd rust
cargo build --release
```

This produces:
- Windows: `rust/target/release/ant_ffi.dll`
- Linux: `rust/target/release/libant_ffi.so`
- macOS: `rust/target/release/libant_ffi.dylib`

#### 2. Build `async_helper` (for async operations)

**Option A: Using Rust (recommended)**
```bash
cd lua/async_helper
cargo build --release
```

**Option B: Using C compiler**
```bash
cd lua/csrc
# Windows (MinGW)
gcc -shared -O2 -o async_helper.dll async_helper.c
# Linux
gcc -shared -O2 -fPIC -o libasync_helper.so async_helper.c
# macOS
gcc -shared -O2 -o libasync_helper.dylib async_helper.c
```

#### 3. Copy libraries to `lua/ant_ffi/`

```bash
# Windows
copy rust\target\release\ant_ffi.dll lua\ant_ffi\
copy lua\async_helper\target\release\async_helper.dll lua\ant_ffi\

# Linux/macOS
cp rust/target/release/libant_ffi.* lua/ant_ffi/
cp lua/async_helper/target/release/libasync_helper.* lua/ant_ffi/
```

### Quick Start

```lua
local ant = require("ant_ffi")

-- Encrypt and decrypt data locally
local encrypted = ant.encrypt("Hello, Autonomi!")
local decrypted = ant.decrypt(encrypted)
print(decrypted)  -- "Hello, Autonomi!"

-- Initialize client (when network is available)
local client = ant.Client.init_local()

-- Create a wallet
local network = ant.Network.new(true)  -- true = local network
local wallet = ant.Wallet.from_private_key(network, "your-private-key")

-- Upload data
local address, cost = client:data_put_public("Hello Autonomi!", wallet)
print("Uploaded to: " .. address:to_hex())
print("Cost: " .. cost)

-- Download data
local downloaded = client:data_get_public(address:to_hex())
print("Downloaded: " .. downloaded)

-- Cleanup
wallet:dispose()
client:dispose()
```

### Running Tests

```bash
cd lua
luajit test/test_self_encryption.lua
luajit test/test_keys.lua
luajit test/test_all_types.lua
luajit test/test_roundtrip.lua  # Requires running local network
```

### Usage Examples

For comprehensive usage examples, see the test files in [`lua/test/`](lua/test/):

| Test File | Features Covered |
|-----------|------------------|
| `test_self_encryption.lua` | Self-encryption, decryption |
| `test_keys.lua` | Secret keys, public keys, key derivation |
| `test_data.lua` | Chunks, addresses, data map chunks |
| `test_all_types.lua` | All data types and operations |
| `test_roundtrip.lua` | Full integration test with network |

## Dart / Flutter

Dart bindings using dart:ffi for the Autonomi network, with Flutter support.

### Prerequisites

- **Dart 3.0+** or **Flutter 3.10+**
- **Rust toolchain** (for building native libraries)

### Building Native Libraries

```bash
# Build the Rust FFI library
cd rust
cargo build --release

# Generate the C header (needed for ffigen)
cargo run -p uniffi-bindgen-swift -- \
  --headers \
  target/release/libant_ffi.so \  # or .dll on Windows, .dylib on macOS
  ../dart/c_header \
  --module-name ant_ffiFFI
```

Copy the native library to your project or ensure it's in the library path:
- Windows: `ant_ffi.dll`
- Linux: `libant_ffi.so`
- macOS: `libant_ffi.dylib`

### Regenerating Bindings

When the Rust API changes, you need to regenerate the Dart FFI bindings. The process involves three steps:

#### 1. Build the Rust library

```bash
cd rust
cargo build --release
```

#### 2. Generate the C header

The C header is generated from the Rust library using `uniffi-bindgen-swift`:

```bash
# From the rust directory
cargo run -p uniffi-bindgen-swift -- \
  --headers \
  target/release/ant_ffi.dll \  # or libant_ffi.so on Linux, libant_ffi.dylib on macOS
  ../dart/c_header \
  --module-name ant_ffiFFI
```

This creates `dart/c_header/ant_ffiFFI.h`.

#### 3. Regenerate Dart bindings with ffigen

```bash
cd dart/ant_ffi
dart run ffigen
```

This reads `ffigen.yaml` and the C header to generate `lib/src/native/bindings.dart`.

**Note:** The generated `bindings.dart` file is committed to the repository for convenience, but can always be regenerated using the steps above.

### Quick Start

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:ant_ffi/ant_ffi.dart';

void main() {
  // Encrypt and decrypt data locally
  final data = Uint8List.fromList(utf8.encode('Hello, Autonomi!'));
  final encrypted = encrypt(data);
  final decrypted = decrypt(encrypted);
  print(utf8.decode(decrypted)); // 'Hello, Autonomi!'

  // Generate keys
  final secretKey = SecretKey.random();
  final publicKey = secretKey.publicKey();
  print('Public key: ${publicKey.toHex()}');

  // Work with chunks
  final chunk = Chunk(data);
  final address = chunk.address();
  print('Chunk address: ${address.toHex()}');

  // Cleanup - important for memory management!
  secretKey.dispose();
  publicKey.dispose();
  chunk.dispose();
  address.dispose();
}
```

### Running Tests

```bash
cd dart/ant_ffi

# Install dependencies and generate bindings
dart pub get
dart run ffigen

# Run tests (requires native library in LD_LIBRARY_PATH)
dart test
```

### Usage Examples

For comprehensive usage examples, see the test files in [`dart/ant_ffi/test/`](dart/ant_ffi/test/):

| Test File | Features Covered |
|-----------|------------------|
| `self_encryption_test.dart` | Self-encryption, decryption |
| `keys_test.dart` | Secret keys, public keys, key derivation |
| `data_types_test.dart` | Chunks, addresses, data operations |

### Flutter Integration

The same bindings work for Flutter apps. Add the native library to your platform-specific directories:
- Android: `android/app/src/main/jniLibs/<arch>/libant_ffi.so`
- iOS: Link as a static library or framework

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
