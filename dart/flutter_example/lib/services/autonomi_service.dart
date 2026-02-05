import 'dart:typed_data';
import 'package:ant_ffi/ant_ffi.dart';

/// Service for interacting with the Autonomi network.
/// Handles connection lifecycle - connects on-demand for each operation.
class AutonomiService {
  // Default Anvil test private key (pre-funded on local testnet)
  static const String _defaultPrivateKey =
      '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

  Client? _client;
  Network? _network;
  Wallet? _wallet;

  bool get isConnected => _client != null;

  /// Connect to the local testnet.
  Future<void> connect() async {
    if (_client != null) return;

    _network = Network.local();
    _wallet = Wallet.fromPrivateKey(_network!, _defaultPrivateKey);
    _client = await Client.initLocal();
  }

  /// Disconnect and release resources.
  void disconnect() {
    _client?.dispose();
    _wallet?.dispose();
    _network?.dispose();
    _client = null;
    _wallet = null;
    _network = null;
  }

  /// Get the estimated cost to upload data.
  Future<String> getQuote(Uint8List data) async {
    await connect();
    try {
      return await _client!.dataCost(data);
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  /// Upload data to the network.
  /// Returns the hex address where the data was stored.
  Future<UploadResult> upload(Uint8List data) async {
    await connect();
    try {
      final result = await _client!.dataPutPublic(
        String.fromCharCodes(data),
        _wallet!,
      );
      return result;
    } finally {
      disconnect();
    }
  }

  /// Download data from the network.
  Future<Uint8List> download(String addressHex) async {
    await connect();
    try {
      final data = await _client!.dataGetPublic(addressHex);
      return Uint8List.fromList(data.codeUnits);
    } finally {
      disconnect();
    }
  }
}
