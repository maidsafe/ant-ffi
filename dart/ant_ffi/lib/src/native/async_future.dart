import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'library.dart';
import 'rust_buffer.dart';

late final _bindings = AntFfiBindings(antFfiLib);

/// Polls a UniFFI future that returns a pointer.
///
/// This function blocks until the future completes by using a simple
/// polling loop with a short delay between iterations.
Future<Pointer<Void>> pollPointerAsync(int futureHandle) async {
  final status = calloc<RustCallStatus>();

  try {
    // Simple polling loop - check if ready, sleep if not
    while (true) {
      // Use a ReceivePort to handle the callback
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      // Create a native callback that sends to the port
      final nativeCallback = NativeCallable<
          Void Function(Uint64, Int8)>.listener((int callbackData, int ready) {
        sendPort.send(ready);
      });

      // Poll the future
      _bindings.ffi_ant_ffi_rust_future_poll_pointer(
        futureHandle,
        nativeCallback.nativeFunction,
        0, // callback_data
      );

      // Wait for the callback
      // pollResult == 0 means ready, non-zero means not ready yet (matches C# binding)
      final pollResult = await receivePort.first as int;
      nativeCallback.close();
      receivePort.close();

      if (pollResult == 0) {
        // Future is ready, complete it
        final result = _bindings.ffi_ant_ffi_rust_future_complete_pointer(
          futureHandle,
          status,
        );
        _checkStatus(status.ref);
        _bindings.ffi_ant_ffi_rust_future_free_pointer(futureHandle);
        return result;
      }

      // Not ready yet, yield and try again
      await Future.delayed(Duration(milliseconds: 1));
    }
  } finally {
    calloc.free(status);
  }
}

/// Polls a UniFFI future that returns a RustBuffer.
Future<RustBuffer> pollRustBufferAsync(int futureHandle) async {
  final status = calloc<RustCallStatus>();

  try {
    while (true) {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      final nativeCallback = NativeCallable<
          Void Function(Uint64, Int8)>.listener((int callbackData, int pollResult) {
        sendPort.send(pollResult);
      });

      _bindings.ffi_ant_ffi_rust_future_poll_rust_buffer(
        futureHandle,
        nativeCallback.nativeFunction,
        0,
      );

      // pollResult == 0 means ready, non-zero means not ready yet
      final pollResult = await receivePort.first as int;
      nativeCallback.close();
      receivePort.close();

      if (pollResult == 0) {
        final result = _bindings.ffi_ant_ffi_rust_future_complete_rust_buffer(
          futureHandle,
          status,
        );
        _checkStatus(status.ref);
        _bindings.ffi_ant_ffi_rust_future_free_rust_buffer(futureHandle);
        return result;
      }

      await Future.delayed(Duration(milliseconds: 1));
    }
  } finally {
    calloc.free(status);
  }
}

/// Polls a UniFFI future that returns void.
Future<void> pollVoidAsync(int futureHandle) async {
  final status = calloc<RustCallStatus>();

  try {
    while (true) {
      final receivePort = ReceivePort();
      final sendPort = receivePort.sendPort;

      final nativeCallback = NativeCallable<
          Void Function(Uint64, Int8)>.listener((int callbackData, int pollResult) {
        sendPort.send(pollResult);
      });

      _bindings.ffi_ant_ffi_rust_future_poll_void(
        futureHandle,
        nativeCallback.nativeFunction,
        0,
      );

      // pollResult == 0 means ready, non-zero means not ready yet
      final pollResult = await receivePort.first as int;
      nativeCallback.close();
      receivePort.close();

      if (pollResult == 0) {
        _bindings.ffi_ant_ffi_rust_future_complete_void(futureHandle, status);
        _checkStatus(status.ref);
        _bindings.ffi_ant_ffi_rust_future_free_void(futureHandle);
        return;
      }

      await Future.delayed(Duration(milliseconds: 1));
    }
  } finally {
    calloc.free(status);
  }
}

void _checkStatus(RustCallStatus status) {
  if (status.code != 0) {
    String errorMessage = 'Async operation failed with code ${status.code}';
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
