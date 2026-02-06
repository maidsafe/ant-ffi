import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// A content-addressed identifier for a chunk on the Autonomi network.
///
/// Chunk addresses are derived from the chunk content using a cryptographic
/// hash function. Two chunks with the same content will have the same address.
class ChunkAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  ChunkAddress._(this._handle);

  /// Internal constructor for creating from a native handle.
  factory ChunkAddress.fromHandle(Pointer<Void> handle) {
    return ChunkAddress._(handle);
  }

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_chunkaddress(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a chunk address from a hex-encoded string.
  ///
  /// Throws [AntFfiException] if the hex string is invalid.
  factory ChunkAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref);
      return ChunkAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a chunk address from raw bytes.
  factory ChunkAddress.fromBytes(Uint8List bytes) {
    final status = calloc<RustCallStatus>();
    try {
      final bytesBuffer = uint8ListToRustBuffer(bytes);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_chunkaddress_new(bytesBuffer, status);
      _checkStatus(status.ref);
      return ChunkAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a chunk address from content data.
  ///
  /// This computes the address that would be assigned to a chunk
  /// containing this data.
  factory ChunkAddress.fromContent(Uint8List data) {
    final status = calloc<RustCallStatus>();
    try {
      final dataBuffer = uint8ListToRustBuffer(data);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(dataBuffer, status);
      _checkStatus(status.ref);
      return ChunkAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_chunkaddress_to_hex(_clone(), status);
      _checkStatus(status.ref);
      final result = rustBufferToString(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to raw bytes.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(_clone(), status);
      _checkStatus(status.ref);
      // Vec<u8> returns with UniFFI length prefix
      final result = rustBufferToUint8ListWithPrefix(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the internal native handle.
  /// Used internally for passing to other FFI functions.
  Pointer<Void> get handle => _handle;

  /// Releases the native resources associated with this address.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_chunkaddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('ChunkAddress has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'ChunkAddress operation failed with code ${status.code}';
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
