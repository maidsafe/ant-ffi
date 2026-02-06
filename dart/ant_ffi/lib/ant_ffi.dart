/// Dart bindings for the Autonomi network.
///
/// This package provides FFI bindings to the ant_ffi Rust library,
/// enabling Dart and Flutter applications to interact with the
/// Autonomi decentralized network.
///
/// ## Quick Start
///
/// ```dart
/// import 'dart:convert';
/// import 'package:ant_ffi/ant_ffi.dart';
///
/// void main() {
///   // Self-encryption example
///   final data = utf8.encode('Hello, Autonomi!');
///   final encrypted = encrypt(Uint8List.fromList(data));
///   final decrypted = decrypt(encrypted);
///   print(utf8.decode(decrypted)); // 'Hello, Autonomi!'
///
///   // Key generation example
///   final secretKey = SecretKey.random();
///   final publicKey = secretKey.publicKey();
///   print('Public key: ${publicKey.toHex()}');
///
///   // Clean up resources
///   secretKey.dispose();
///   publicKey.dispose();
/// }
/// ```
///
/// ## Memory Management
///
/// All objects that wrap native resources (SecretKey, PublicKey, Chunk,
/// ChunkAddress) must be explicitly disposed when no longer needed by
/// calling their `dispose()` method.
library ant_ffi;

// Self-encryption functions
export 'src/self_encryption.dart' show encrypt, decrypt, encryptString, decryptToString;

// Type wrappers
export 'src/types/secret_key.dart' show SecretKey;
export 'src/types/public_key.dart' show PublicKey;
export 'src/types/chunk.dart' show Chunk, chunkMaxSize, chunkMaxRawSize;
export 'src/types/address.dart' show ChunkAddress;
export 'src/types/network.dart' show Network;
export 'src/types/wallet.dart' show Wallet;
export 'src/types/data_address.dart' show DataAddress;

// Client
export 'src/client.dart' show Client, UploadResult;

// Exceptions
export 'src/native/rust_buffer.dart' show AntFfiException;
