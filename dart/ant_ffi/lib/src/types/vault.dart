import 'dart:ffi';
import 'dart:typed_data';
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

/// Secret key for accessing a user's vault.
class VaultSecretKey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  VaultSecretKey._(this._handle);

  /// Creates a VaultSecretKey from a raw handle.
  factory VaultSecretKey.fromHandle(Pointer<Void> handle) {
    return VaultSecretKey._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_vaultsecretkey(_handle, status);
      _checkStatus(status.ref, 'VaultSecretKey.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Generates a random vault secret key.
  factory VaultSecretKey.random() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(status);
      _checkStatus(status.ref, 'VaultSecretKey.random');
      return VaultSecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a VaultSecretKey from a hex-encoded string.
  factory VaultSecretKey.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'VaultSecretKey.fromHex');
      return VaultSecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the vault secret key to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(_clone(), status);
      _checkStatus(status.ref, 'VaultSecretKey.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_vaultsecretkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('VaultSecretKey has been disposed');
    }
  }
}

/// User data stored in a vault.
class UserData {
  final Pointer<Void> _handle;
  bool _disposed = false;

  UserData._(this._handle);

  /// Creates a UserData from a raw handle.
  factory UserData.fromHandle(Pointer<Void> handle) {
    return UserData._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_userdata(_handle, status);
      _checkStatus(status.ref, 'UserData.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates new empty user data.
  factory UserData.create() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_userdata_new(status);
      _checkStatus(status.ref, 'UserData.create');
      return UserData._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the file archives (serialized).
  Uint8List fileArchives() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_userdata_file_archives(_clone(), status);
      _checkStatus(status.ref, 'UserData.fileArchives');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the private file archives (serialized).
  Uint8List privateFileArchives() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_userdata_private_file_archives(_clone(), status);
      _checkStatus(status.ref, 'UserData.privateFileArchives');
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
      _bindings.uniffi_ant_ffi_fn_free_userdata(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('UserData has been disposed');
    }
  }
}
