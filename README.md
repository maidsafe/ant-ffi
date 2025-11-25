# Autonomi FFI Bindings

Android and iOS bindings for the Autonomi network.

[![JitPack](https://jitpack.io/v/maidsafe/ant-ffi.svg)](https://jitpack.io/#maidsafe/ant-ffi)

## Android Installation

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
    implementation("com.github.maidsafe:ant-ffi:1.0.0")
}
```

## Quick Start

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

## iOS Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/maidsafe/ant-ffi.git", from: "1.0.0")
]
```

## Available APIs

- **Data**: Upload and download public/private data
- **Registers**: Mutable versioned storage
- **Vaults**: Encrypted user data storage
- **Pointers**: Mutable references to data
- **Scratchpads**: Encrypted mutable data with versioning
- **GraphEntry**: Graph-based data structures

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.
