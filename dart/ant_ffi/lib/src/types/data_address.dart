import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// An address for public data stored on the Autonomi network.
///
/// Data addresses are content-addressed identifiers returned when
/// uploading public data.
class DataAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  DataAddress._(this._handle);

  /// Internal constructor for creating from a native handle.
  factory DataAddress.fromHandle(Pointer<Void> handle) {
    return DataAddress._(handle);
  }

  /// Clones the internal handle for passing to FFI.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_dataaddress(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a data address from a hex-encoded string.
  factory DataAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref);
      return DataAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_dataaddress_to_hex(_clone(), status);
      _checkStatus(status.ref);
      final result = rustBufferToString(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Releases the native resources associated with this address.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_dataaddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DataAddress has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'DataAddress operation failed with code ${status.code}';
    if (status.errorBuf.len > 0) {
      try {
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
