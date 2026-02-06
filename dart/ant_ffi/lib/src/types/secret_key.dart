import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'public_key.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// A BLS secret key used for signing and deriving public keys.
///
/// Secret keys should be kept confidential and never shared.
class SecretKey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  SecretKey._(this._handle);

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_secretkey(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by other types (e.g., key derivation).
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new random secret key.
  ///
  /// Example:
  /// ```dart
  /// final key = SecretKey.random();
  /// print('Key: ${key.toHex()}');
  /// key.dispose();
  /// ```
  factory SecretKey.random() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_secretkey_random(status);
      _checkStatus(status.ref);
      return SecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a secret key from a hex-encoded string.
  ///
  /// Throws [AntFfiException] if the hex string is invalid.
  factory SecretKey.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_secretkey_from_hex(hexBuffer, status);
      _checkStatus(status.ref);
      return SecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the secret key to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_secretkey_to_hex(_clone(), status);
      _checkStatus(status.ref);
      final result = rustBufferToString(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Derives the public key from this secret key.
  ///
  /// The public key can be safely shared and is used to verify signatures.
  PublicKey publicKey() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_secretkey_public_key(_clone(), status);
      _checkStatus(status.ref);
      return PublicKey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Releases the native resources associated with this key.
  ///
  /// After calling dispose, the key can no longer be used.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_secretkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('SecretKey has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'SecretKey operation failed with code ${status.code}';
    if (status.errorBuf.len > 0) {
      try {
        // Error buffers use UniFFI format with length prefix
        errorMessage = rustBufferToStringWithPrefix(status.errorBuf);
      } catch (_) {
        try {
          errorMessage = rustBufferToString(status.errorBuf);
        } catch (_) {}
      }
    }
    throw AntFfiException(errorMessage, status.code);
  }
}
