import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// Network configuration for connecting to Autonomi.
///
/// Use [Network.local] for local testnet or [Network.mainnet] for production.
class Network {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Network._(this._handle);

  /// Clones the internal handle for passing to FFI.
  /// Required because UniFFI consumes one Arc reference per call.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_network(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a network configuration for local testnet.
  factory Network.local() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_network_new(1, status);
      _checkStatus(status.ref);
      return Network._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a network configuration for mainnet.
  factory Network.mainnet() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_network_new(0, status);
      _checkStatus(status.ref);
      return Network._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates a custom network configuration.
  factory Network.custom({
    required String rpcUrl,
    required String paymentTokenAddress,
    required String dataPaymentsAddress,
    String? royaltiesPkHex,
  }) {
    final status = calloc<RustCallStatus>();
    try {
      final rpcBuffer = stringToRustBuffer(rpcUrl);
      final tokenBuffer = stringToRustBuffer(paymentTokenAddress);
      final dataBuffer = stringToRustBuffer(dataPaymentsAddress);
      final royaltiesBuffer = optionStringToRustBuffer(royaltiesPkHex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_network_custom(
        rpcBuffer,
        tokenBuffer,
        dataBuffer,
        royaltiesBuffer,
        status,
      );
      _checkStatus(status.ref);
      return Network._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the internal handle for FFI calls.
  Pointer<Void> get handle => _clone();

  /// Releases the native resources associated with this network.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_network(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Network has been disposed');
    }
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Network operation failed with code ${status.code}';
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
