import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'network.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// A wallet for making payments on the Autonomi network.
///
/// Wallets are created from EVM private keys and used to pay for
/// storage operations.
class Wallet {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Wallet._(this._handle);

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_wallet(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a wallet from an EVM private key.
  ///
  /// The private key should be a hex-encoded string, optionally with
  /// a "0x" prefix.
  ///
  /// Example:
  /// ```dart
  /// final network = Network.local();
  /// final wallet = Wallet.fromPrivateKey(
  ///   network,
  ///   '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
  /// );
  /// print('Address: ${wallet.address()}');
  /// wallet.dispose();
  /// network.dispose();
  /// ```
  factory Wallet.fromPrivateKey(Network network, String privateKey) {
    final status = calloc<RustCallStatus>();
    try {
      final keyBuffer = stringToRustBuffer(privateKey);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(
        network.handle,
        keyBuffer,
        status,
      );
      _checkStatus(status.ref);
      return Wallet._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Gets the wallet's EVM address.
  ///
  /// Returns the hex-encoded address (with 0x prefix).
  String address() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final resultBuffer = _bindings.uniffi_ant_ffi_fn_method_wallet_address(_clone(), status);
      _checkStatus(status.ref);
      final result = rustBufferToString(resultBuffer);
      resultBuffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the internal handle for FFI calls.
  Pointer<Void> get handle => _clone();

  /// Releases the native resources associated with this wallet.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_wallet(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Wallet has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Wallet operation failed with code ${status.code}';
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
