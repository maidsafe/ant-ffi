import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'public_key.dart';
import 'secret_key.dart';

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

/// Address of a graph entry on the network.
class GraphEntryAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  GraphEntryAddress._(this._handle);

  /// Creates a GraphEntryAddress from a raw handle.
  factory GraphEntryAddress.fromHandle(Pointer<Void> handle) {
    return GraphEntryAddress._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_graphentryaddress(_handle, status);
      _checkStatus(status.ref, 'GraphEntryAddress.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a GraphEntryAddress from a public key.
  factory GraphEntryAddress.fromPublicKey(PublicKey publicKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_graphentryaddress_new(
        publicKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'GraphEntryAddress.fromPublicKey');
      return GraphEntryAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a GraphEntryAddress from an owner's public key.
  /// This is an alias for [fromPublicKey].
  factory GraphEntryAddress.fromOwner(PublicKey owner) {
    return GraphEntryAddress.fromPublicKey(owner);
  }

  /// Creates a GraphEntryAddress from a hex-encoded string.
  factory GraphEntryAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'GraphEntryAddress.fromHex');
      return GraphEntryAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(_clone(), status);
      _checkStatus(status.ref, 'GraphEntryAddress.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_graphentryaddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('GraphEntryAddress has been disposed');
    }
  }
}

/// A graph entry that can be linked to other entries on the network.
class GraphEntry {
  final Pointer<Void> _handle;
  bool _disposed = false;

  GraphEntry._(this._handle);

  /// Creates a GraphEntry from a raw handle.
  factory GraphEntry.fromHandle(Pointer<Void> handle) {
    return GraphEntry._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_graphentry(_handle, status);
      _checkStatus(status.ref, 'GraphEntry.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new GraphEntry.
  /// Note: parents and descendants are serialized as Vec<GraphEntryAddress>.
  factory GraphEntry.create(
    SecretKey owner,
    Uint8List parents,
    Uint8List content,
    Uint8List descendants,
  ) {
    final status = calloc<RustCallStatus>();
    try {
      final parentsBuffer = uint8ListToRustBuffer(parents);
      final contentBuffer = uint8ListToRustBuffer(content);
      final descendantsBuffer = uint8ListToRustBuffer(descendants);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_graphentry_new(
        owner.cloneHandle(),
        parentsBuffer,
        contentBuffer,
        descendantsBuffer,
        status,
      );
      _checkStatus(status.ref, 'GraphEntry.create');
      return GraphEntry._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the address of this graph entry.
  GraphEntryAddress address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_graphentry_address(_clone(), status);
      _checkStatus(status.ref, 'GraphEntry.address');
      return GraphEntryAddress.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the content of this graph entry.
  Uint8List content() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_graphentry_content(_clone(), status);
      _checkStatus(status.ref, 'GraphEntry.content');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the parent entries (serialized).
  Uint8List parents() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_graphentry_parents(_clone(), status);
      _checkStatus(status.ref, 'GraphEntry.parents');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the descendant entries (serialized).
  Uint8List descendants() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_graphentry_descendants(_clone(), status);
      _checkStatus(status.ref, 'GraphEntry.descendants');
      final result = rustBufferToUint8ListWithPrefix(buffer);
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
      _bindings.uniffi_ant_ffi_fn_free_graphentry(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('GraphEntry has been disposed');
    }
  }
}
