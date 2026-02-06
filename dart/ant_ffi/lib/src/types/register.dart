import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'public_key.dart';

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

/// Address of a register on the network.
class RegisterAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  RegisterAddress._(this._handle);

  /// Creates a RegisterAddress from a raw handle.
  factory RegisterAddress.fromHandle(Pointer<Void> handle) {
    return RegisterAddress._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_registeraddress(_handle, status);
      _checkStatus(status.ref, 'RegisterAddress.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a RegisterAddress from a public key (owner).
  factory RegisterAddress.fromOwner(PublicKey owner) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_registeraddress_new(
        owner.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'RegisterAddress.fromOwner');
      return RegisterAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a RegisterAddress from a hex-encoded string.
  factory RegisterAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'RegisterAddress.fromHex');
      return RegisterAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the owner public key of this register address.
  PublicKey owner() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_registeraddress_owner(_clone(), status);
      _checkStatus(status.ref, 'RegisterAddress.owner');
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
      final buffer = _bindings.uniffi_ant_ffi_fn_method_registeraddress_to_hex(_clone(), status);
      _checkStatus(status.ref, 'RegisterAddress.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_registeraddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('RegisterAddress has been disposed');
    }
  }
}
