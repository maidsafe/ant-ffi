import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'address.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// A chunk of data that can be stored on the Autonomi network.
///
/// Chunks are the fundamental unit of storage. Each chunk has a content-based
/// address derived from its data.
class Chunk {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Chunk._(this._handle);

  /// Creates a Chunk from a raw FFI handle.
  factory Chunk.fromHandle(Pointer<Void> handle) {
    return Chunk._(handle);
  }

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_chunk(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a new chunk from the given data.
  ///
  /// Example:
  /// ```dart
  /// final chunk = Chunk(Uint8List.fromList(utf8.encode('Hello!')));
  /// print('Address: ${chunk.address().toHex()}');
  /// chunk.dispose();
  /// ```
  factory Chunk(Uint8List value) {
    final status = calloc<RustCallStatus>();
    try {
      final valueBuffer = uint8ListToRustBuffer(value);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_chunk_new(valueBuffer, status);
      _checkStatus(status.ref);
      return Chunk._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Gets the content-based address of this chunk.
  ChunkAddress address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_chunk_address(_clone(), status);
      _checkStatus(status.ref);
      return ChunkAddress.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Gets the data stored in this chunk.
  Uint8List value() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_chunk_value(_clone(), status);
      _checkStatus(status.ref);
      // Vec<u8> returns with UniFFI length prefix
      final result = rustBufferToUint8ListWithPrefix(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Gets the size of the chunk in bytes.
  int size() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_chunk_size(_clone(), status);
      _checkStatus(status.ref);
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Checks if the chunk exceeds the maximum allowed size.
  bool isTooBig() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_chunk_is_too_big(_clone(), status);
      _checkStatus(status.ref);
      return result != 0;
    } finally {
      calloc.free(status);
    }
  }

  /// Releases the native resources associated with this chunk.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_chunk(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Chunk has been disposed');
    }
  }
}

/// Returns the maximum size of chunk content in bytes.
int chunkMaxSize() {
  final status = calloc<RustCallStatus>();
  try {
    final result = _bindings.uniffi_ant_ffi_fn_func_chunk_max_size(status);
    _checkStatus(status.ref);
    return result;
  } finally {
    calloc.free(status);
  }
}

/// Returns the maximum raw size of a chunk (including overhead) in bytes.
int chunkMaxRawSize() {
  final status = calloc<RustCallStatus>();
  try {
    final result = _bindings.uniffi_ant_ffi_fn_func_chunk_max_raw_size(status);
    _checkStatus(status.ref);
    return result;
  } finally {
    calloc.free(status);
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Chunk operation failed with code ${status.code}';
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
