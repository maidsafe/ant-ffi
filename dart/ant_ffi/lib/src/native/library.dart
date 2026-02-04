import 'dart:ffi';
import 'dart:io';

/// Loads the ant_ffi native library for the current platform.
DynamicLibrary loadAntFfiLibrary() {
  if (Platform.isWindows) {
    return DynamicLibrary.open('ant_ffi.dll');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libant_ffi.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libant_ffi.so');
  } else if (Platform.isAndroid) {
    return DynamicLibrary.open('libant_ffi.so');
  } else if (Platform.isIOS) {
    // On iOS, the library is statically linked
    return DynamicLibrary.process();
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

/// The loaded ant_ffi native library.
/// This is a lazy singleton that loads the library on first access.
late final DynamicLibrary antFfiLib = loadAntFfiLibrary();
