import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'secret_key.dart';
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

/// Index for deriving child keys from a master key.
///
/// DerivationIndex is a 32-byte value used in hierarchical key derivation.
class DerivationIndex {
  final Pointer<Void> _handle;
  bool _disposed = false;

  DerivationIndex._(this._handle);

  /// Creates a DerivationIndex from a raw handle.
  factory DerivationIndex.fromHandle(Pointer<Void> handle) {
    return DerivationIndex._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_derivationindex(_handle, status);
      _checkStatus(status.ref, 'DerivationIndex.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Generates a random derivation index.
  factory DerivationIndex.random() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_derivationindex_random(status);
      _checkStatus(status.ref, 'DerivationIndex.random');
      return DerivationIndex._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a derivation index from 32 bytes.
  factory DerivationIndex.fromBytes(Uint8List bytes) {
    if (bytes.length != 32) {
      throw ArgumentError('DerivationIndex must be exactly 32 bytes, got ${bytes.length}');
    }
    final status = calloc<RustCallStatus>();
    try {
      final buffer = uint8ListToRustBuffer(bytes);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(buffer, status);
      _checkStatus(status.ref, 'DerivationIndex.fromBytes');
      return DerivationIndex._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the 32-byte representation of this derivation index.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_derivationindex_to_bytes(_clone(), status);
      _checkStatus(status.ref, 'DerivationIndex.toBytes');
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
      _bindings.uniffi_ant_ffi_fn_free_derivationindex(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DerivationIndex has been disposed');
    }
  }
}

/// BLS Signature (96 bytes).
class Signature {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Signature._(this._handle);

  /// Creates a Signature from a raw handle.
  factory Signature.fromHandle(Pointer<Void> handle) {
    return Signature._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_signature(_handle, status);
      _checkStatus(status.ref, 'Signature.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a signature from raw bytes (96 bytes for BLS signatures).
  factory Signature.fromBytes(Uint8List bytes) {
    if (bytes.length != 96) {
      throw ArgumentError('Signature must be exactly 96 bytes, got ${bytes.length}');
    }
    final status = calloc<RustCallStatus>();
    try {
      final buffer = uint8ListToRustBuffer(bytes);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_signature_from_bytes(buffer, status);
      _checkStatus(status.ref, 'Signature.fromBytes');
      return Signature._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the 96-byte representation of this signature.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_signature_to_bytes(_clone(), status);
      _checkStatus(status.ref, 'Signature.toBytes');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns true if the signature contains an odd number of ones (parity bit).
  bool parity() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_signature_parity(_clone(), status);
      _checkStatus(status.ref, 'Signature.parity');
      return result != 0;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the hex representation of this signature.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_signature_to_hex(_clone(), status);
      _checkStatus(status.ref, 'Signature.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_signature(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Signature has been disposed');
    }
  }
}

/// Master secret key for hierarchical key derivation.
/// Can be used to derive multiple child keys.
class MainSecretKey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  MainSecretKey._(this._handle);

  /// Creates a MainSecretKey from a raw handle.
  factory MainSecretKey.fromHandle(Pointer<Void> handle) {
    return MainSecretKey._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_mainsecretkey(_handle, status);
      _checkStatus(status.ref, 'MainSecretKey.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a MainSecretKey from a SecretKey.
  factory MainSecretKey.fromSecretKey(SecretKey secretKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_mainsecretkey_new(
        secretKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'MainSecretKey.fromSecretKey');
      return MainSecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Generates a random MainSecretKey.
  factory MainSecretKey.random() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_mainsecretkey_random(status);
      _checkStatus(status.ref, 'MainSecretKey.random');
      return MainSecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the matching MainPubkey.
  MainPubkey publicKey() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_mainsecretkey_public_key(_clone(), status);
      _checkStatus(status.ref, 'MainSecretKey.publicKey');
      return MainPubkey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Signs a message with this secret key.
  Signature sign(Uint8List message) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final msgBuffer = uint8ListToRustBuffer(message);
      final handle = _bindings.uniffi_ant_ffi_fn_method_mainsecretkey_sign(_clone(), msgBuffer, status);
      _checkStatus(status.ref, 'MainSecretKey.sign');
      return Signature.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Derives a DerivedSecretKey from this master key using the given index.
  DerivedSecretKey deriveKey(DerivationIndex index) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(
        _clone(),
        index._clone(),
        status,
      );
      _checkStatus(status.ref, 'MainSecretKey.deriveKey');
      return DerivedSecretKey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Generates a new random DerivedSecretKey from this master key.
  DerivedSecretKey randomDerivedKey() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(_clone(), status);
      _checkStatus(status.ref, 'MainSecretKey.randomDerivedKey');
      return DerivedSecretKey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the raw bytes of the secret key.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(_clone(), status);
      _checkStatus(status.ref, 'MainSecretKey.toBytes');
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
      _bindings.uniffi_ant_ffi_fn_free_mainsecretkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('MainSecretKey has been disposed');
    }
  }
}

/// Master public key for hierarchical key derivation.
class MainPubkey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  MainPubkey._(this._handle);

  /// Creates a MainPubkey from a raw handle.
  factory MainPubkey.fromHandle(Pointer<Void> handle) {
    return MainPubkey._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_mainpubkey(_handle, status);
      _checkStatus(status.ref, 'MainPubkey.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a MainPubkey from a PublicKey.
  factory MainPubkey.fromPublicKey(PublicKey publicKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_mainpubkey_new(
        publicKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'MainPubkey.fromPublicKey');
      return MainPubkey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a MainPubkey from a hex string.
  factory MainPubkey.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'MainPubkey.fromHex');
      return MainPubkey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Verifies that a signature is valid for the given message.
  bool verify(Signature signature, Uint8List message) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final msgBuffer = uint8ListToRustBuffer(message);
      final result = _bindings.uniffi_ant_ffi_fn_method_mainpubkey_verify(
        _clone(),
        signature._clone(),
        msgBuffer,
        status,
      );
      _checkStatus(status.ref, 'MainPubkey.verify');
      return result != 0;
    } finally {
      calloc.free(status);
    }
  }

  /// Derives a DerivedPubkey from this master public key using the given index.
  DerivedPubkey deriveKey(DerivationIndex index) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_mainpubkey_derive_key(
        _clone(),
        index._clone(),
        status,
      );
      _checkStatus(status.ref, 'MainPubkey.deriveKey');
      return DerivedPubkey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the bytes representation of this public key.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(_clone(), status);
      _checkStatus(status.ref, 'MainPubkey.toBytes');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the hex representation of this public key.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_mainpubkey_to_hex(_clone(), status);
      _checkStatus(status.ref, 'MainPubkey.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_mainpubkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('MainPubkey has been disposed');
    }
  }
}

/// Derived secret key from hierarchical key derivation.
class DerivedSecretKey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  DerivedSecretKey._(this._handle);

  /// Creates a DerivedSecretKey from a raw handle.
  factory DerivedSecretKey.fromHandle(Pointer<Void> handle) {
    return DerivedSecretKey._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_derivedsecretkey(_handle, status);
      _checkStatus(status.ref, 'DerivedSecretKey.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a DerivedSecretKey from a SecretKey.
  factory DerivedSecretKey.fromSecretKey(SecretKey secretKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(
        secretKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'DerivedSecretKey.fromSecretKey');
      return DerivedSecretKey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Gets the corresponding DerivedPubkey.
  DerivedPubkey publicKey() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(_clone(), status);
      _checkStatus(status.ref, 'DerivedSecretKey.publicKey');
      return DerivedPubkey.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Signs a message with this derived secret key.
  Signature sign(Uint8List message) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final msgBuffer = uint8ListToRustBuffer(message);
      final handle = _bindings.uniffi_ant_ffi_fn_method_derivedsecretkey_sign(_clone(), msgBuffer, status);
      _checkStatus(status.ref, 'DerivedSecretKey.sign');
      return Signature.fromHandle(handle);
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
      _bindings.uniffi_ant_ffi_fn_free_derivedsecretkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DerivedSecretKey has been disposed');
    }
  }
}

/// Derived public key from hierarchical key derivation.
class DerivedPubkey {
  final Pointer<Void> _handle;
  bool _disposed = false;

  DerivedPubkey._(this._handle);

  /// Creates a DerivedPubkey from a raw handle.
  factory DerivedPubkey.fromHandle(Pointer<Void> handle) {
    return DerivedPubkey._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_derivedpubkey(_handle, status);
      _checkStatus(status.ref, 'DerivedPubkey.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a DerivedPubkey from a PublicKey.
  factory DerivedPubkey.fromPublicKey(PublicKey publicKey) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_derivedpubkey_new(
        publicKey.cloneHandle(),
        status,
      );
      _checkStatus(status.ref, 'DerivedPubkey.fromPublicKey');
      return DerivedPubkey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a DerivedPubkey from a hex string.
  factory DerivedPubkey.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'DerivedPubkey.fromHex');
      return DerivedPubkey._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Verifies that a signature is valid for the given message.
  bool verify(Signature signature, Uint8List message) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final msgBuffer = uint8ListToRustBuffer(message);
      final result = _bindings.uniffi_ant_ffi_fn_method_derivedpubkey_verify(
        _clone(),
        signature._clone(),
        msgBuffer,
        status,
      );
      _checkStatus(status.ref, 'DerivedPubkey.verify');
      return result != 0;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the bytes representation of this public key.
  Uint8List toBytes() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(_clone(), status);
      _checkStatus(status.ref, 'DerivedPubkey.toBytes');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the hex representation of this public key.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(_clone(), status);
      _checkStatus(status.ref, 'DerivedPubkey.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_derivedpubkey(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('DerivedPubkey has been disposed');
    }
  }
}
