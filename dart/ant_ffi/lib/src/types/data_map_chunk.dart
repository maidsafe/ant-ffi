import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

void _checkStatus(RustCallStatus status, String operation) {
  if (status.code != 0) {
    String errorMessage = '$operation failed with code ${status.code}';
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

/// Metadata for encrypted private data on the network.
///
/// A DataMapChunk contains the information needed to decrypt and reassemble
/// data that was encrypted using self-encryption before being stored.
class DataMapChunk {
  final Pointer<Void> _handle;
  bool _disposed = false;

  DataMapChunk._(this._handle);

  /// Creates a DataMapChunk from a raw handle.
  factory DataMapChunk.fromHandle(Pointer<Void> handle) {
    return DataMapChunk._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_datamapchunk(_handle, status);
      _checkStatus(status.ref, 'DataMapChunk.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a DataMapChunk from a hex-encoded string.
  factory DataMapChunk.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'DataMapChunk.fromHex');
      return DataMapChunk._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the data map to a hex-encoded string for storage or transmission.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_datamapchunk_to_hex(_clone(), status);
      _checkStatus(status.ref, 'DataMapChunk.toHex');
      final result = rustBufferToString(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the network address where this data map is stored.
  String address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_datamapchunk_address(_clone(), status);
      _checkStatus(status.ref, 'DataMapChunk.address');
      final result = rustBufferToString(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Releases the native resources.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_datamapchunk(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DataMapChunk has been disposed');
    }
  }
}
