import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'library.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// Extension methods for working with RustBuffer.
extension RustBufferExtension on RustBuffer {
  /// Converts a RustBuffer to a Uint8List.
  /// The returned list is a copy of the data.
  Uint8List toUint8List() {
    if (len == 0) return Uint8List(0);
    return Uint8List.fromList(data.cast<Uint8>().asTypedList(len));
  }

  /// Frees the RustBuffer memory.
  void free() {
    final status = calloc<RustCallStatus>();
    try {
      _bindings.ffi_ant_ffi_rustbuffer_free(this, status);
      _checkStatus(status.ref);
    } finally {
      calloc.free(status);
    }
  }
}

/// Creates a RustBuffer from a Uint8List with UniFFI length prefix.
/// Used for Vec<u8> parameters passed to FFI functions.
RustBuffer uint8ListToRustBuffer(Uint8List data) {
  final status = calloc<RustCallStatus>();
  try {
    // UniFFI serialization: 4-byte big-endian length prefix + data
    final serialized = Uint8List(4 + data.length);
    // Write big-endian length
    serialized[0] = (data.length >> 24) & 0xFF;
    serialized[1] = (data.length >> 16) & 0xFF;
    serialized[2] = (data.length >> 8) & 0xFF;
    serialized[3] = data.length & 0xFF;
    // Copy data
    serialized.setRange(4, 4 + data.length, data);

    final foreignBytes = calloc<ForeignBytes>();
    foreignBytes.ref.len = serialized.length;
    foreignBytes.ref.data = calloc<Uint8>(serialized.length);
    foreignBytes.ref.data.cast<Uint8>().asTypedList(serialized.length).setAll(0, serialized);

    final buffer = _bindings.ffi_ant_ffi_rustbuffer_from_bytes(foreignBytes.ref, status);
    _checkStatus(status.ref);

    calloc.free(foreignBytes.ref.data);
    calloc.free(foreignBytes);

    return buffer;
  } finally {
    calloc.free(status);
  }
}

/// Creates a RustBuffer from raw bytes (no UniFFI prefix).
/// Used for strings and pre-serialized data (like encrypted output).
RustBuffer rawBytesToRustBuffer(Uint8List data) {
  final status = calloc<RustCallStatus>();
  try {
    final foreignBytes = calloc<ForeignBytes>();
    foreignBytes.ref.len = data.length;
    foreignBytes.ref.data = calloc<Uint8>(data.length);
    foreignBytes.ref.data.cast<Uint8>().asTypedList(data.length).setAll(0, data);

    final buffer = _bindings.ffi_ant_ffi_rustbuffer_from_bytes(foreignBytes.ref, status);
    _checkStatus(status.ref);

    calloc.free(foreignBytes.ref.data);
    calloc.free(foreignBytes);

    return buffer;
  } finally {
    calloc.free(status);
  }
}

/// Creates a RustBuffer from a String.
/// Strings are passed to FFI as raw UTF-8 bytes (no length prefix).
RustBuffer stringToRustBuffer(String str) {
  final bytes = Uint8List.fromList(utf8.encode(str));
  return rawBytesToRustBuffer(bytes);
}

/// Extracts a Uint8List from a RustBuffer with UniFFI length prefix.
/// Used for Vec<u8> data inside compound types (records).
Uint8List rustBufferToUint8ListWithPrefix(RustBuffer buffer) {
  if (buffer.len < 4) return Uint8List(0);

  final data = buffer.data.cast<Uint8>().asTypedList(buffer.len);
  // Read big-endian length from first 4 bytes
  final length = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];

  if (length == 0) return Uint8List(0);
  if (4 + length > buffer.len) {
    throw StateError('Invalid RustBuffer: declared length $length exceeds buffer size ${buffer.len - 4}');
  }

  return Uint8List.fromList(data.sublist(4, 4 + length));
}

/// Extracts raw bytes from a RustBuffer without any prefix parsing.
/// Used for raw byte arrays and strings returned directly from FFI methods.
Uint8List rustBufferToUint8List(RustBuffer buffer) {
  if (buffer.len == 0) return Uint8List(0);
  return Uint8List.fromList(buffer.data.cast<Uint8>().asTypedList(buffer.len));
}

/// Extracts a String from a RustBuffer (raw UTF-8, no length prefix).
/// Used for strings returned directly from FFI methods like toHex().
String rustBufferToString(RustBuffer buffer) {
  final bytes = rustBufferToUint8List(buffer);
  return utf8.decode(bytes);
}

/// Extracts a String from a RustBuffer with UniFFI length prefix.
/// Used for strings inside compound types (records).
String rustBufferToStringWithPrefix(RustBuffer buffer) {
  final bytes = rustBufferToUint8ListWithPrefix(buffer);
  return utf8.decode(bytes);
}

/// Checks the RustCallStatus and throws an exception if there was an error.
void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'FFI call failed with code ${status.code}';
    if (status.errorBuf.len > 0) {
      try {
        // Error buffers use UniFFI format with length prefix
        errorMessage = rustBufferToStringWithPrefix(status.errorBuf);
      } catch (_) {
        // Fallback to raw if prefix parsing fails
        try {
          errorMessage = rustBufferToString(status.errorBuf);
        } catch (_) {
          // If we can't decode the error, use the default message
        }
      }
    }
    throw AntFfiException(errorMessage, status.code);
  }
}

/// Exception thrown when an FFI call fails.
class AntFfiException implements Exception {
  final String message;
  final int code;

  AntFfiException(this.message, this.code);

  @override
  String toString() => 'AntFfiException: $message (code: $code)';
}
