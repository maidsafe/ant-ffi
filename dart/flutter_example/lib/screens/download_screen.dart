import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/autonomi_service.dart';
import '../services/storage_service.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _autonomi = AutonomiService();
  final _storage = StorageService();
  final _addressController = TextEditingController();

  String _status = 'Ready';
  bool _loading = false;
  String? _savedPath;

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

  Future<void> _download() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _setStatus('Please enter an address');
      return;
    }

    _setLoading(true);
    _setStatus('Connecting to network...');
    setState(() => _savedPath = null);

    try {
      _setStatus('Downloading...');
      final data = await _autonomi.download(address);

      // Ask user where to save
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save downloaded file',
        fileName: 'download_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsBytes(data);

        if (mounted) {
          setState(() {
            _savedPath = savePath;
            _status = 'Download complete!';
          });
        }
      } else {
        _setStatus('Save cancelled');
      }
    } catch (e) {
      await _storage.logError('download', e.toString());
      _setStatus('Error: $e');
    } finally {
      _setLoading(false);
      _autonomi.disconnect();
    }
  }

  @override
  void dispose() {
    _autonomi.disconnect();
    _addressController.dispose();
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

          const SizedBox(height: 24),

          // Address input
          Text(
            'Enter Data Address',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Paste hex address here (0x...)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _addressController.clear(),
              ),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            maxLines: 3,
            minLines: 1,
          ),

          const SizedBox(height: 16),

          // Download button
          FilledButton.icon(
            onPressed: _loading ? null : _download,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),

          // Result
          if (_savedPath != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'File saved!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _savedPath!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Help text
          Text(
            'Enter the hex address from a previous upload to download the file.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
