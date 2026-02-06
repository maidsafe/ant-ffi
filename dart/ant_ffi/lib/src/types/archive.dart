import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import '../native/bindings.dart';
import '../native/library.dart';
import '../native/rust_buffer.dart';
import 'data_address.dart';
import 'data_map_chunk.dart';

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

/// Address of an archive on the network.
class ArchiveAddress {
  final Pointer<Void> _handle;
  bool _disposed = false;

  ArchiveAddress._(this._handle);

  /// Creates an ArchiveAddress from a raw handle.
  factory ArchiveAddress.fromHandle(Pointer<Void> handle) {
    return ArchiveAddress._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_archiveaddress(_handle, status);
      _checkStatus(status.ref, 'ArchiveAddress.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates an ArchiveAddress from a hex-encoded string.
  factory ArchiveAddress.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'ArchiveAddress.fromHex');
      return ArchiveAddress._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts the address to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_archiveaddress_to_hex(_clone(), status);
      _checkStatus(status.ref, 'ArchiveAddress.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_archiveaddress(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('ArchiveAddress has been disposed');
    }
  }
}

/// Metadata for a file in an archive.
class Metadata {
  final Pointer<Void> _handle;
  bool _disposed = false;

  Metadata._(this._handle);

  /// Creates Metadata from a raw handle.
  factory Metadata.fromHandle(Pointer<Void> handle) {
    return Metadata._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_metadata(_handle, status);
      _checkStatus(status.ref, 'Metadata.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by other operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates new metadata with only size.
  factory Metadata.create(int size) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_metadata_new(size, status);
      _checkStatus(status.ref, 'Metadata.create');
      return Metadata._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Creates new metadata with timestamps.
  factory Metadata.withTimestamps(int size, int created, int modified) {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(
        size,
        created,
        modified,
        status,
      );
      _checkStatus(status.ref, 'Metadata.withTimestamps');
      return Metadata._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the size in bytes.
  int size() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_metadata_size(_clone(), status);
      _checkStatus(status.ref, 'Metadata.size');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the creation timestamp.
  int created() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_metadata_created(_clone(), status);
      _checkStatus(status.ref, 'Metadata.created');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the modification timestamp.
  int modified() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_metadata_modified(_clone(), status);
      _checkStatus(status.ref, 'Metadata.modified');
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
      _bindings.uniffi_ant_ffi_fn_free_metadata(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Metadata has been disposed');
    }
  }
}

/// A public archive containing files accessible by anyone with the address.
class PublicArchive {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PublicArchive._(this._handle);

  /// Creates a PublicArchive from a raw handle.
  factory PublicArchive.fromHandle(Pointer<Void> handle) {
    return PublicArchive._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_publicarchive(_handle, status);
      _checkStatus(status.ref, 'PublicArchive.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new empty public archive.
  factory PublicArchive.create() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_publicarchive_new(status);
      _checkStatus(status.ref, 'PublicArchive.create');
      return PublicArchive._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Adds a file to the archive.
  /// Returns a new archive with the file added (archives are immutable).
  PublicArchive addFile(String path, DataAddress address, Metadata metadata) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final pathBuffer = stringToRustBuffer(path);
      final handle = _bindings.uniffi_ant_ffi_fn_method_publicarchive_add_file(
        _clone(),
        pathBuffer,
        address.cloneHandle(),
        metadata._clone(),
        status,
      );
      _checkStatus(status.ref, 'PublicArchive.addFile');
      return PublicArchive.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Renames a file in the archive.
  /// Returns a new archive with the file renamed.
  PublicArchive renameFile(String oldPath, String newPath) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final oldPathBuffer = stringToRustBuffer(oldPath);
      final newPathBuffer = stringToRustBuffer(newPath);
      final handle = _bindings.uniffi_ant_ffi_fn_method_publicarchive_rename_file(
        _clone(),
        oldPathBuffer,
        newPathBuffer,
        status,
      );
      _checkStatus(status.ref, 'PublicArchive.renameFile');
      return PublicArchive.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the list of files in the archive (serialized).
  Uint8List files() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_publicarchive_files(_clone(), status);
      _checkStatus(status.ref, 'PublicArchive.files');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the number of files in the archive.
  int fileCount() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_publicarchive_file_count(_clone(), status);
      _checkStatus(status.ref, 'PublicArchive.fileCount');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the addresses of all files in the archive (serialized).
  Uint8List addresses() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_publicarchive_addresses(_clone(), status);
      _checkStatus(status.ref, 'PublicArchive.addresses');
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
      _bindings.uniffi_ant_ffi_fn_free_publicarchive(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PublicArchive has been disposed');
    }
  }
}

/// A private archive containing encrypted files.
class PrivateArchive {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PrivateArchive._(this._handle);

  /// Creates a PrivateArchive from a raw handle.
  factory PrivateArchive.fromHandle(Pointer<Void> handle) {
    return PrivateArchive._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_privatearchive(_handle, status);
      _checkStatus(status.ref, 'PrivateArchive.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a new empty private archive.
  factory PrivateArchive.create() {
    final status = calloc<RustCallStatus>();
    try {
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_privatearchive_new(status);
      _checkStatus(status.ref, 'PrivateArchive.create');
      return PrivateArchive._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Adds a file to the archive.
  /// Returns a new archive with the file added.
  PrivateArchive addFile(String path, DataMapChunk dataMap, Metadata metadata) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final pathBuffer = stringToRustBuffer(path);
      final handle = _bindings.uniffi_ant_ffi_fn_method_privatearchive_add_file(
        _clone(),
        pathBuffer,
        dataMap.cloneHandle(),
        metadata._clone(),
        status,
      );
      _checkStatus(status.ref, 'PrivateArchive.addFile');
      return PrivateArchive.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Renames a file in the archive.
  /// Returns a new archive with the file renamed.
  PrivateArchive renameFile(String oldPath, String newPath) {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final oldPathBuffer = stringToRustBuffer(oldPath);
      final newPathBuffer = stringToRustBuffer(newPath);
      final handle = _bindings.uniffi_ant_ffi_fn_method_privatearchive_rename_file(
        _clone(),
        oldPathBuffer,
        newPathBuffer,
        status,
      );
      _checkStatus(status.ref, 'PrivateArchive.renameFile');
      return PrivateArchive.fromHandle(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the list of files in the archive (serialized).
  Uint8List files() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_privatearchive_files(_clone(), status);
      _checkStatus(status.ref, 'PrivateArchive.files');
      final result = rustBufferToUint8ListWithPrefix(buffer);
      buffer.free();
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the number of files in the archive.
  int fileCount() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final result = _bindings.uniffi_ant_ffi_fn_method_privatearchive_file_count(_clone(), status);
      _checkStatus(status.ref, 'PrivateArchive.fileCount');
      return result;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns the data maps of all files in the archive (serialized).
  Uint8List dataMaps() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_privatearchive_data_maps(_clone(), status);
      _checkStatus(status.ref, 'PrivateArchive.dataMaps');
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
      _bindings.uniffi_ant_ffi_fn_free_privatearchive(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PrivateArchive has been disposed');
    }
  }
}

/// Data map for a private archive.
class PrivateArchiveDataMap {
  final Pointer<Void> _handle;
  bool _disposed = false;

  PrivateArchiveDataMap._(this._handle);

  /// Creates a PrivateArchiveDataMap from a raw handle.
  factory PrivateArchiveDataMap.fromHandle(Pointer<Void> handle) {
    return PrivateArchiveDataMap._(handle);
  }

  Pointer<Void> _clone() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final cloned = _bindings.uniffi_ant_ffi_fn_clone_privatearchivedatamap(_handle, status);
      _checkStatus(status.ref, 'PrivateArchiveDataMap.clone');
      return cloned;
    } finally {
      calloc.free(status);
    }
  }

  /// Returns a cloned handle for use by client operations.
  Pointer<Void> cloneHandle() => _clone();

  /// Creates a PrivateArchiveDataMap from a hex-encoded string.
  factory PrivateArchiveDataMap.fromHex(String hex) {
    final status = calloc<RustCallStatus>();
    try {
      final hexBuffer = stringToRustBuffer(hex);
      final handle = _bindings.uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(hexBuffer, status);
      _checkStatus(status.ref, 'PrivateArchiveDataMap.fromHex');
      return PrivateArchiveDataMap._(handle);
    } finally {
      calloc.free(status);
    }
  }

  /// Converts to a hex-encoded string.
  String toHex() {
    _checkNotDisposed();
    final status = calloc<RustCallStatus>();
    try {
      final buffer = _bindings.uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(_clone(), status);
      _checkStatus(status.ref, 'PrivateArchiveDataMap.toHex');
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
      _bindings.uniffi_ant_ffi_fn_free_privatearchivedatamap(_handle, status);
    } finally {
      calloc.free(status);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('PrivateArchiveDataMap has been disposed');
    }
  }
}
