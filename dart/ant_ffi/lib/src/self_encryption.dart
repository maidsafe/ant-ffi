import 'dart:convert';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'native/bindings.dart';
import 'native/library.dart';
import 'native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// Encrypts data using self-encryption.
///
/// Self-encryption splits the data into chunks and encrypts each chunk
/// using content from other chunks. The result contains both the encrypted
/// data and the metadata needed to decrypt it.
///
/// Example:
/// ```dart
/// final encrypted = encrypt(Uint8List.fromList(utf8.encode('Hello!')));
/// ```
Uint8List encrypt(Uint8List data) {
  final status = calloc<RustCallStatus>();
  try {
    final inputBuffer = uint8ListToRustBuffer(data);
    final resultBuffer = _bindings.uniffi_ant_ffi_fn_func_encrypt(inputBuffer, status);
    _checkStatus(status.ref);

    // Return raw bytes - encrypted data keeps its internal serialization format
    final result = rustBufferToUint8List(resultBuffer);
    resultBuffer.free();
    return result;
  } finally {
    calloc.free(status);
  }
}

/// Decrypts self-encrypted data.
///
/// Takes the encrypted data returned by [encrypt] and returns the
/// original plaintext data.
///
/// Example:
/// ```dart
/// final decrypted = decrypt(encrypted);
/// print(utf8.decode(decrypted)); // 'Hello!'
/// ```
Uint8List decrypt(Uint8List encrypted) {
  final status = calloc<RustCallStatus>();
  try {
    // Encrypted data is already serialized - pass as raw bytes (no prefix)
    final inputBuffer = rawBytesToRustBuffer(encrypted);
    final resultBuffer = _bindings.uniffi_ant_ffi_fn_func_decrypt(inputBuffer, status);
    _checkStatus(status.ref);

    // Vec<u8> returns with UniFFI length prefix
    final result = rustBufferToUint8ListWithPrefix(resultBuffer);
    resultBuffer.free();
    return result;
  } finally {
    calloc.free(status);
  }
}

/// Encrypts a string using self-encryption.
///
/// Convenience method that converts the string to UTF-8 bytes, encrypts it,
/// and returns the encrypted bytes.
Uint8List encryptString(String data) {
  return encrypt(Uint8List.fromList(utf8.encode(data)));
}

/// Decrypts self-encrypted data and returns it as a string.
///
/// Convenience method that decrypts the data and converts it back
/// to a UTF-8 string.
String decryptToString(Uint8List encrypted) {
  final decrypted = decrypt(encrypted);
  return utf8.decode(decrypted);
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Encryption/decryption failed with code ${status.code}';
    if (status.errorBuf.len > 0) {
      try {
        // Error buffers use UniFFI format with length prefix
        errorMessage = rustBufferToStringWithPrefix(status.errorBuf);
      } catch (_) {
        try {
          errorMessage = rustBufferToString(status.errorBuf);
        } catch (_) {
          // Use default message if error decoding fails
        }
      }
    }
    throw AntFfiException(errorMessage, status.code);
  }
}
