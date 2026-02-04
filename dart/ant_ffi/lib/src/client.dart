import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'native/bindings.dart';
import 'native/library.dart';
import 'native/rust_buffer.dart';
import 'native/async_future.dart';
import 'types/data_address.dart';
import 'types/network.dart';
import 'types/wallet.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// Result of a data upload operation.
class UploadResult {
  /// The address where the data was stored.
  final DataAddress address;

  /// The cost of the upload (as a string representation of the amount).
  final String cost;

  UploadResult(this.address, this.cost);
}

/// A client for interacting with the Autonomi network.
///
/// The client provides methods for uploading and downloading data.
/// All network operations are asynchronous.
class Client {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Client._(this._handle);

  /// Clones the internal handle for passing to FFI.
  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_client(_handle, status);
      _checkStatus(status.ref);
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Initializes a client connected to a local testnet.
  ///
  /// Requires a local Autonomi network to be running.
  /// See: `antctl local status`
  static Future<Client> initLocal() async {
    final futureHandle = _bindings.uniffi_ant_ffi_fn_constructor_client_init_local();
    final handle = await pollPointerAsync(futureHandle);
    return Client._(handle);
  }

  /// Initializes a client connected to mainnet.
  static Future<Client> init() async {
    final futureHandle = _bindings.uniffi_ant_ffi_fn_constructor_client_init();
    final handle = await pollPointerAsync(futureHandle);
    return Client._(handle);
  }

  /// Initializes a client with specific peer addresses.
  ///
  /// Use this when `initLocal()` doesn't work (e.g., on Windows).
  ///
  /// Example:
  /// ```dart
  /// final network = Network.local();
  /// final client = await Client.initWithPeers(
  ///   ['/ip4/127.0.0.1/udp/60619/quic-v1/p2p/12D3KooW...'],
  ///   network,
  /// );
  /// ```
  static Future<Client> initWithPeers(
    List<String> peers,
    Network network, {
    String? dataDir,
  }) async {
    final peersBuffer = _serializeStringList(peers);
    final dataDirBuffer = _serializeOptionString(dataDir);

    final futureHandle = _bindings.uniffi_ant_ffi_fn_constructor_client_init_with_peers(
      peersBuffer,
      network.handle,
      dataDirBuffer,
    );

    final handle = await pollPointerAsync(futureHandle);
    return Client._(handle);
  }

  /// Uploads public data to the network.
  ///
  /// Returns the address where the data was stored and the cost.
  ///
  /// Example:
  /// ```dart
  /// final client = await Client.initLocal();
  /// final network = Network.local();
  /// final wallet = Wallet.fromPrivateKey(network, privateKey);
  ///
  /// final result = await client.dataPutPublic('Hello, Autonomi!', wallet);
  /// print('Stored at: ${result.address.toHex()}');
  /// print('Cost: ${result.cost}');
  /// ```
  Future<UploadResult> dataPutPublic(String data, Wallet wallet) async {
    _checkNotDisposed();

    final dataBuffer = uint8ListToRustBuffer(Uint8List.fromList(utf8.encode(data)));
    final paymentBuffer = _lowerPaymentOption(wallet);

    final futureHandle = _bindings.uniffi_ant_ffi_fn_method_client_data_put_public(
      _clone(),
      dataBuffer,
      paymentBuffer,
    );

    final resultBuffer = await pollRustBufferAsync(futureHandle);

    // Deserialize UploadResult: two strings with 4-byte BE length prefixes
    final resultData = resultBuffer.data.cast<Uint8>().asTypedList(resultBuffer.len);

    // Read price string
    final priceLen = (resultData[0] << 24) |
        (resultData[1] << 16) |
        (resultData[2] << 8) |
        resultData[3];
    final price = utf8.decode(resultData.sublist(4, 4 + priceLen));

    // Read address string (starts after price)
    final offset = 4 + priceLen;
    final addrLen = (resultData[offset] << 24) |
        (resultData[offset + 1] << 16) |
        (resultData[offset + 2] << 8) |
        resultData[offset + 3];
    final addressHex = utf8.decode(resultData.sublist(offset + 4, offset + 4 + addrLen));

    resultBuffer.free();

    return UploadResult(DataAddress.fromHex(addressHex), price);
  }

  /// Downloads public data from the network.
  ///
  /// Takes a hex-encoded address and returns the data as a string.
  ///
  /// Example:
  /// ```dart
  /// final data = await client.dataGetPublic(addressHex);
  /// print('Downloaded: $data');
  /// ```
  Future<String> dataGetPublic(String addressHex) async {
    _checkNotDisposed();

    final addrBuffer = stringToRustBuffer(addressHex);

    final futureHandle = _bindings.uniffi_ant_ffi_fn_method_client_data_get_public(
      _clone(),
      addrBuffer,
    );

    final resultBuffer = await pollRustBufferAsync(futureHandle);
    final result = rustBufferToStringWithPrefix(resultBuffer);
    resultBuffer.free();

    return result;
  }

  /// Releases the native resources associated with this client.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final status = calloc<RustCallStatus>();
    try {
      _bindings.uniffi_ant_ffi_fn_free_client(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Client has been disposed');
    }
  }
}

/// Serializes a PaymentOption::WalletPayment enum for FFI.
///
/// UniFFI enum format: 4-byte BE variant index + variant fields.
/// WalletPayment variant (index 1) contains a Wallet pointer.
RustBuffer _lowerPaymentOption(Wallet wallet) {
  final status = calloc<RustCallStatus>();
  try {
    // Total size: 4 bytes (variant index) + 8 bytes (pointer)
    const totalLen = 12;
    final data = Uint8List(totalLen);

    // Write 4-byte big-endian variant index (1 = WalletPayment)
    data[0] = 0;
    data[1] = 0;
    data[2] = 0;
    data[3] = 1;

    // Write 8-byte pointer (big-endian)
    final ptrValue = wallet.handle.address;
    data[4] = (ptrValue >> 56) & 0xFF;
    data[5] = (ptrValue >> 48) & 0xFF;
    data[6] = (ptrValue >> 40) & 0xFF;
    data[7] = (ptrValue >> 32) & 0xFF;
    data[8] = (ptrValue >> 24) & 0xFF;
    data[9] = (ptrValue >> 16) & 0xFF;
    data[10] = (ptrValue >> 8) & 0xFF;
    data[11] = ptrValue & 0xFF;

    // Create RustBuffer from raw bytes (no length prefix)
    return rawBytesToRustBuffer(data);
  } finally {
    calloc.free(status);
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Client operation failed with code ${status.code}';
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

/// Serializes a List<String> for UniFFI.
/// Format: 4-byte BE count + each string (4-byte BE length + UTF-8 bytes).
RustBuffer _serializeStringList(List<String> strings) {
  // Calculate total size
  int totalSize = 4; // count
  for (final s in strings) {
    final bytes = utf8.encode(s);
    totalSize += 4 + bytes.length; // length + data
  }

  final data = Uint8List(totalSize);
  int offset = 0;

  // Write count (4-byte BE)
  data[offset++] = (strings.length >> 24) & 0xFF;
  data[offset++] = (strings.length >> 16) & 0xFF;
  data[offset++] = (strings.length >> 8) & 0xFF;
  data[offset++] = strings.length & 0xFF;

  // Write each string
  for (final s in strings) {
    final bytes = utf8.encode(s);

    // Write length (4-byte BE)
    data[offset++] = (bytes.length >> 24) & 0xFF;
    data[offset++] = (bytes.length >> 16) & 0xFF;
    data[offset++] = (bytes.length >> 8) & 0xFF;
    data[offset++] = bytes.length & 0xFF;

    // Write data
    data.setRange(offset, offset + bytes.length, bytes);
    offset += bytes.length;
  }

  return rawBytesToRustBuffer(data);
}

/// Serializes an Option<String> for UniFFI.
/// Format: 1 byte (0=None, 1=Some) + optional string (4-byte BE length + UTF-8 bytes).
RustBuffer _serializeOptionString(String? value) {
  if (value == null) {
    return rawBytesToRustBuffer(Uint8List.fromList([0])); // None
  }

  final bytes = utf8.encode(value);
  final data = Uint8List(1 + 4 + bytes.length);
  int offset = 0;

  // Write Some indicator
  data[offset++] = 1;

  // Write length (4-byte BE)
  data[offset++] = (bytes.length >> 24) & 0xFF;
  data[offset++] = (bytes.length >> 16) & 0xFF;
  data[offset++] = (bytes.length >> 8) & 0xFF;
  data[offset++] = bytes.length & 0xFF;

  // Write data
  data.setRange(offset, offset + bytes.length, bytes);

  return rawBytesToRustBuffer(data);
}
