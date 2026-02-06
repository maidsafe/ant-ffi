import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'public_key.dart';
import 'secret_key.dart';
import 'address.dart';
import 'scratchpad.dart';
import 'graph_entry.dart';

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

/// Address of a network pointer.
class PointerAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PointerAddress._(this._handle);

  /// Creates a PointerAddress from a raw handle.
  factory PointerAddress.fromHandle(Pointer<Void> handle) {
    return PointerAddress._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_pointeraddress(_handle, status);
      _checkStatus(status.ref, 'PointerAddress.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a PointerAddress from a public key.
  factory PointerAddress.fromPublicKey(PublicKey publicKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointeraddress_new(
        publicKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'PointerAddress.fromPublicKey');
      return PointerAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a PointerAddress from a hex-encoded string.
  factory PointerAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'PointerAddress.fromHex');
      return PointerAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the owner public key of this pointer address.
  PublicKey owner() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_pointeraddress_owner(_clone(), status);
      _checkStatus(status.ref, 'PointerAddress.owner');
      return PublicKey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_pointeraddress_to_hex(_clone(), status);
      _checkStatus(status.ref, 'PointerAddress.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_pointeraddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PointerAddress has been disposed');
    }
  }
}

/// Target of a network pointer. Can point to various data types.
class PointerTarget {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PointerTarget._(this._handle);

  /// Creates a PointerTarget from a raw handle.
  factory PointerTarget.fromHandle(Pointer<Void> handle) {
    return PointerTarget._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_pointertarget(_handle, status);
      _checkStatus(status.ref, 'PointerTarget.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by other operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a PointerTarget pointing to a chunk.
  factory PointerTarget.chunk(ChunkAddress address) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointertarget_chunk(
        address.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'PointerTarget.chunk');
      return PointerTarget._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a PointerTarget pointing to another pointer.
  factory PointerTarget.pointer(PointerAddress address) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointertarget_pointer(
        address._clone(),
        status,
      );
      _checkStatus(status.ref, 'PointerTarget.pointer');
      return PointerTarget._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a PointerTarget pointing to a graph entry.
  factory PointerTarget.graphEntry(GraphEntryAddress address) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(
        address.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'PointerTarget.graphEntry');
      return PointerTarget._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a PointerTarget pointing to a scratchpad.
  factory PointerTarget.scratchpad(ScratchpadAddress address) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(
        address.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'PointerTarget.scratchpad');
      return PointerTarget._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the target to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_pointertarget_to_hex(_clone(), status);
      _checkStatus(status.ref, 'PointerTarget.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_pointertarget(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PointerTarget has been disposed');
    }
  }
}

/// A mutable pointer on the network that can be updated to point to different targets.
class NetworkPointer {
  final Pointer<Void> _handle;
  bool _disposed = false;

  NetworkPointer._(this._handle);

  /// Creates a NetworkPointer from a raw handle.
  factory NetworkPointer.fromHandle(Pointer<Void> handle) {
    return NetworkPointer._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_networkpointer(_handle, status);
      _checkStatus(status.ref, 'NetworkPointer.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new NetworkPointer with the given secret key, counter, and target.
  factory NetworkPointer.create(SecretKey key, int counter, PointerTarget target) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_networkpointer_new(
        key.cloneHandle(),
        counter,
        target._clone(),
        status,
      );
      _checkStatus(status.ref, 'NetworkPointer.create');
      return NetworkPointer._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the address of this pointer.
  PointerAddress address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_networkpointer_address(_clone(), status);
      _checkStatus(status.ref, 'NetworkPointer.address');
      return PointerAddress.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the target this pointer points to.
  PointerTarget target() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_networkpointer_target(_clone(), status);
      _checkStatus(status.ref, 'NetworkPointer.target');
      return PointerTarget.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the counter value of this pointer.
  int counter() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_networkpointer_counter(_clone(), status);
      _checkStatus(status.ref, 'NetworkPointer.counter');
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
      _bindings.uniffi_ant_ffi_fn_free_networkpointer(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('NetworkPointer has been disposed');
    }
  }
}
