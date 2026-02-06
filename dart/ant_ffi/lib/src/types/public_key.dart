import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// A BLS public key used for verifying signatures.
///
/// Public keys can be safely shared and are derived from secret keys.
class PublicKey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PublicKey._(this._handle);

  /// Internal constructor for creating from a native handle.
  factory PublicKey.fromHandle(Pointer<Void> handle) {
    return PublicKey._(handle);
  }

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_publickey(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a public key from a hex-encoded string.
  ///
  /// Throws [AntFfiException] if the hex string is invalid.
  factory PublicKey.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_publickey_from_hex(hexBuffer, status);
      _checkStatus(status.ref);
      return PublicKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the public key to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_publickey_to_hex(_clone(), status);
      _checkStatus(status.ref);
      final result = rustBufferToString(resultBuffer);
      resultBuffer.free();
      return result;
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
      _bindings.uniffi_ant_ffi_fn_free_publickey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PublicKey has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'PublicKey operation failed with code ${status.code}';
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
