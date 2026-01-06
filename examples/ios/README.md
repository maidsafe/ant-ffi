# Autonomi iOS Example

A simple SwiftUI app demonstrating how to use the Autonomi library.

## Features

- **Encryption Test**: Demonstrates local encryption and decryption using `encrypt()` and `decrypt()`
- **Client Init Test**: Shows how to initialize an Autonomi client for local testnet

## Requirements

- Xcode 15.0+
- iOS 16.0+ / macOS 10.15+
- Swift 5.10+

## Getting Started

1. **Open the project in Xcode:**
   ```bash
   cd examples/ios
   open WithAutonomi.xcodeproj
   ```

2. **Wait for Swift Package Manager** to download the Autonomi dependency (this happens automatically).

3. **Select a target** (iOS Simulator or your device) and click **Run**.

## Project Structure

```
WithAutonomi/
├── WithAutonomiApp.swift   # App entry point
├── ContentView.swift       # Main UI with demo buttons
└── Assets.xcassets/        # App icons and colors
```

## Code Highlights

### Encryption (Synchronous)

```swift
import Autonomi

let data: [UInt8] = Array("Hello, Autonomi!".utf8)
let encrypted = try encrypt(data)
let decrypted = try decrypt(encrypted)
let message = String(bytes: decrypted, encoding: .utf8)!
```

### Client Initialization (Async)

```swift
import Autonomi

// For local testnet
let client = try await Client.initLocal()

// For mainnet (requires peers)
let client = try await Client.init()
```

## Customization

To modify the example:

1. Edit `ContentView.swift` to add more API demonstrations
2. The Autonomi dependency is configured via SPM in the project settings

## Troubleshooting

**"No such module 'Autonomi'"**
- Ensure SPM has finished resolving packages (File → Packages → Resolve Package Versions)

**Build errors about missing XCFramework**
- Clean build folder (Cmd+Shift+K) and rebuild

**Client init fails**
- The `initLocal()` method requires a local Autonomi testnet running
- Use offline features like `encrypt()`/`decrypt()` without a network

## License

This example is part of the [ant-ffi](https://github.com/maidsafe/ant-ffi) project and is licensed under the BSD 3-Clause License.
