import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../services/autonomi_service.dart';
import '../services/storage_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _autonomi = AutonomiService();
  final _storage = StorageService();

  String _status = 'Ready';
  bool _loading = false;
  bool _dragging = false;

  // Selected file info
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;

  // Quote info
  String? _quote;

  // Upload result
  String? _uploadedAddress;

  void _setStatus(String status) {
    if (mounted) {
      setState(() => _status = status);
    }
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _loading = loading);
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      _handleFile(File(result.files.single.path!));
    }
  }

  void _handleFile(File file) {
    setState(() {
      _selectedFile = file;
      _fileName = file.path.split(Platform.pathSeparator).last;
      _fileSize = file.lengthSync();
      _quote = null;
      _uploadedAddress = null;
    });
    _getQuote();
  }

  Future<void> _getQuote() async {
    if (_selectedFile == null) return;

    _setLoading(true);
    _setStatus('Connecting to network...');

    try {
      final data = await _selectedFile!.readAsBytes();
      _setStatus('Getting quote...');
      final quote = await _autonomi.getQuote(data);

      if (mounted) {
        setState(() {
          _quote = quote;
          _status = 'Quote received';
        });
      }
    } catch (e) {
      await _storage.logError('getQuote', e.toString());
      _setStatus('Error: $e');
      _autonomi.disconnect();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _approveUpload() async {
    if (_selectedFile == null) return;

    _setLoading(true);
    _setStatus('Uploading...');

    try {
      final data = await _selectedFile!.readAsBytes();
      final result = await _autonomi.upload(data);

      final address = result.address.toHex();
      await _storage.logUpload(
        filename: _fileName!,
        address: address,
        size: _fileSize!,
        cost: result.cost,
      );

      if (mounted) {
        setState(() {
          _uploadedAddress = address;
          _status = 'Upload complete!';
        });
      }
    } catch (e) {
      await _storage.logError('upload', e.toString());
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
      _autonomi.disconnect();
    }
  }

  void _cancel() {
    _autonomi.disconnect();
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _quote = null;
      _uploadedAddress = null;
      _status = 'Ready';
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  void dispose() {
    _autonomi.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Expanded(child: Text('Status: $_status')),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Drop zone
          Expanded(
            child: DropTarget(
              onDragDone: (details) {
                if (details.files.isNotEmpty) {
                  _handleFile(File(details.files.first.path));
                }
              },
              onDragEntered: (_) => setState(() => _dragging = true),
              onDragExited: (_) => setState(() => _dragging = false),
              child: GestureDetector(
                onTap: _loading ? null : _selectFile,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _dragging
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: _dragging ? 3 : 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _dragging
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3)
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Drop file here',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'or tap to select',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // File info and actions
          if (_selectedFile != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fileName ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Size: ${_formatBytes(_fileSize ?? 0)}'),
                    if (_quote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimated cost: $_quote',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (_uploadedAddress != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        'Address: $_uploadedAddress',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _loading ? null : _cancel,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        if (_quote != null && _uploadedAddress == null)
                          FilledButton(
                            onPressed: _loading ? null : _approveUpload,
                            child: const Text('Approve Upload'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
