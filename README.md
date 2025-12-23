# Autonomi FFI Bindings

Android and iOS bindings for the Autonomi network.

[![JitPack](https://jitpack.io/v/maidsafe/ant-ffi.svg)](https://jitpack.io/#maidsafe/ant-ffi)

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

## Available APIs

- **Data**: Upload and download public/private data
- **Registers**: Mutable versioned storage
- **Vaults**: Encrypted user data storage
- **Pointers**: Mutable references to data
- **Scratchpads**: Encrypted mutable data with versioning
- **GraphEntry**: Graph-based data structures

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
