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

/// Address of a scratchpad on the network.
class ScratchpadAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  ScratchpadAddress._(this._handle);

  /// Creates a ScratchpadAddress from a raw handle.
  factory ScratchpadAddress.fromHandle(Pointer<Void> handle) {
    return ScratchpadAddress._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_scratchpadaddress(_handle, status);
      _checkStatus(status.ref, 'ScratchpadAddress.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a ScratchpadAddress from a public key.
  factory ScratchpadAddress.fromPublicKey(PublicKey publicKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(
        publicKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'ScratchpadAddress.fromPublicKey');
      return ScratchpadAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a ScratchpadAddress from a hex-encoded string.
  factory ScratchpadAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'ScratchpadAddress.fromHex');
      return ScratchpadAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the owner public key of this scratchpad address.
  PublicKey owner() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_scratchpadaddress_owner(_clone(), status);
      _checkStatus(status.ref, 'ScratchpadAddress.owner');
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
      final buffer = _bindings.uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(_clone(), status);
      _checkStatus(status.ref, 'ScratchpadAddress.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_scratchpadaddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('ScratchpadAddress has been disposed');
    }
  }
}

/// A mutable scratchpad for storing temporary data on the network.
class Scratchpad {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Scratchpad._(this._handle);

  /// Creates a Scratchpad from a raw handle.
  factory Scratchpad.fromHandle(Pointer<Void> handle) {
    return Scratchpad._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_scratchpad(_handle, status);
      _checkStatus(status.ref, 'Scratchpad.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new Scratchpad.
  factory Scratchpad.create(SecretKey owner, int dataEncoding, Uint8List data, int counter) {
    final status = calloc<RustCallStatus>();
    try {
      final dataBuffer = uint8ListToRustBuffer(data);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_scratchpad_new(
        owner.cloneHandle(),
        dataEncoding,
        dataBuffer,
        counter,
        status,
      );
      _checkStatus(status.ref, 'Scratchpad.create');
      return Scratchpad._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the address of this scratchpad.
  ScratchpadAddress address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_scratchpad_address(_clone(), status);
      _checkStatus(status.ref, 'Scratchpad.address');
      return ScratchpadAddress.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the data encoding type.
  int dataEncoding() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_scratchpad_data_encoding(_clone(), status);
      _checkStatus(status.ref, 'Scratchpad.dataEncoding');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the counter value.
  int counter() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_scratchpad_counter(_clone(), status);
      _checkStatus(status.ref, 'Scratchpad.counter');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Decrypts and returns the data using the owner's secret key.
  Uint8List decryptData(SecretKey secretKey) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(
        _clone(),
        secretKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'Scratchpad.decryptData');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the owner public key.
  PublicKey owner() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_scratchpad_owner(_clone(), status);
      _checkStatus(status.ref, 'Scratchpad.owner');
      return PublicKey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the encrypted data.
  Uint8List encryptedData() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(_clone(), status);
      _checkStatus(status.ref, 'Scratchpad.encryptedData');
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
      _bindings.uniffi_ant_ffi_fn_free_scratchpad(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Scratchpad has been disposed');
    }
  }
}
