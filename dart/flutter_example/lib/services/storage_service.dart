import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Record of a successful upload.
class UploadRecord {
  final String filename;
  final String address;
  final int size;
  final String cost;
  final DateTime timestamp;

  UploadRecord({
    required this.filename,
    required this.address,
    required this.size,
    required this.cost,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'address': address,
        'size': size,
        'cost': cost,
        'timestamp': timestamp.toIso8601String(),
      };

  factory UploadRecord.fromJson(Map<String, dynamic> json) => UploadRecord(
        filename: json['filename'] as String,
        address: json['address'] as String,
        size: json['size'] as int,
        cost: json['cost'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Service for local storage of upload history and error logs.
class StorageService {
  File? _uploadsFile;
  File? _errorsFile;

  Future<void> _ensureInitialized() async {
    if (_uploadsFile != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _uploadsFile = File('${dir.path}/autonomi_uploads.json');
    _errorsFile = File('${dir.path}/autonomi_errors.log');
  }

  /// Log a successful upload.
  Future<void> logUpload({
    required String filename,
    required String address,
    required int size,
    required String cost,
  }) async {
    await _ensureInitialized();

    final records = await getUploadHistory();
    records.add(UploadRecord(
      filename: filename,
      address: address,
      size: size,
      cost: cost,
      timestamp: DateTime.now(),
    ));

    final json = records.map((r) => r.toJson()).toList();
    await _uploadsFile!.writeAsString(jsonEncode(json));
  }

  /// Get all upload records.
  Future<List<UploadRecord>> getUploadHistory() async {
    await _ensureInitialized();

    if (!await _uploadsFile!.exists()) {
      return [];
    }

    try {
      final content = await _uploadsFile!.readAsString();
      if (content.isEmpty) return [];

      final json = jsonDecode(content) as List;
      return json
          .map((e) => UploadRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Log an error.
  Future<void> logError(String operation, String error) async {
    await _ensureInitialized();

    final line = '[${DateTime.now().toIso8601String()}] $operation: $error\n';
    await _errorsFile!.writeAsString(line, mode: FileMode.append);
  }

  /// Get path to uploads file for display.
  Future<String> getUploadsFilePath() async {
    await _ensureInitialized();
    return _uploadsFile!.path;
  }
}
