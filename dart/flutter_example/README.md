# Autonomi Flutter Example

A Flutter app demonstrating file upload and download to the Autonomi network.

## Features

- **Upload**: Drag-and-drop or select files to upload
- **Quote**: See estimated cost before uploading
- **Download**: Retrieve files using their address
- **History**: View past uploads with addresses

## Prerequisites

1. **Local Testnet**: Start the Autonomi testnet before running:
   ```bash
   cd C:\tools\ant
   setup-testnet.bat
   ```

2. **Native Library**: Copy `ant_ffi.dll` to the app's build directory

## Platform Setup

### Windows

1. Build the Rust library:
   ```bash
   cd rust/autonomi
   cargo build --release
   ```

2. Copy `target/release/ant_ffi.dll` to:
   - `build/windows/runner/Release/` (for release builds)
   - Or the same directory as the executable

### macOS

1. Build the Rust library:
   ```bash
   cd rust/autonomi
   cargo build --release
   ```

2. Copy `target/release/libant_ffi.dylib` to your app bundle's Frameworks folder

### Linux

1. Build the Rust library:
   ```bash
   cd rust/autonomi
   cargo build --release
   ```

2. Copy `target/release/libant_ffi.so` to `/usr/local/lib/` or app directory

### Android

1. Build for Android architectures:
   ```bash
   cargo build --release --target aarch64-linux-android
   cargo build --release --target x86_64-linux-android
   ```

2. Copy `.so` files to:
   ```
   android/app/src/main/jniLibs/arm64-v8a/libant_ffi.so
   android/app/src/main/jniLibs/x86_64/libant_ffi.so
   ```

### iOS

iOS requires static linking. Add the Autonomi.xcframework to your Xcode project.

## Running

```bash
cd dart/flutter_example
flutter pub get
flutter run
```

## Usage

### Upload Flow
1. Open the app
2. Drop a file or tap to select
3. View the estimated cost
4. Tap "Approve Upload" to upload
5. Copy the address from the result or History tab

### Download Flow
1. Go to the Download tab
2. Paste the file address
3. Tap "Download"
4. Choose where to save the file

## Test Wallet

The app uses the default Anvil test wallet:
- Address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Private Key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

This wallet is pre-funded on the local testnet.

## Logs

- **Upload history**: `<documents>/autonomi_uploads.json`
- **Error log**: `<documents>/autonomi_errors.log`
