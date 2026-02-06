package antffi

/*
#include <stdint.h>

typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// Callback type for async polling
typedef void (*UniffiRustFutureContinuationCallback)(uint64_t callback_data, int8_t poll_result);

// Pointer futures
extern void ffi_ant_ffi_rust_future_poll_pointer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern void* ffi_ant_ffi_rust_future_complete_pointer(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_pointer(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_pointer(uint64_t handle);

// RustBuffer futures
extern void ffi_ant_ffi_rust_future_poll_rust_buffer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern RustBuffer ffi_ant_ffi_rust_future_complete_rust_buffer(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_rust_buffer(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_rust_buffer(uint64_t handle);

// Void futures
extern void ffi_ant_ffi_rust_future_poll_void(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern void ffi_ant_ffi_rust_future_complete_void(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_void(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_void(uint64_t handle);

// Go callback that will be called from Rust
void goAsyncCallback(uint64_t callback_data, int8_t poll_result);
*/
import "C"

import (
	"context"
	"sync"
	"sync/atomic"
	"unsafe"
)

// callbackRegistry stores channels for async callbacks
var (
	callbackCounter uint64
	callbackMap     sync.Map // map[uint64]chan int8
)

// registerCallback creates a channel for an async operation and returns its ID
func registerCallback() (uint64, chan int8) {
	id := atomic.AddUint64(&callbackCounter, 1)
	ch := make(chan int8, 1)
	callbackMap.Store(id, ch)
	return id, ch
}

// unregisterCallback removes a callback from the registry
func unregisterCallback(id uint64) {
	callbackMap.Delete(id)
}

//export goAsyncCallback
func goAsyncCallback(callbackData C.uint64_t, pollResult C.int8_t) {
	id := uint64(callbackData)
	if val, ok := callbackMap.Load(id); ok {
		ch := val.(chan int8)
		select {
		case ch <- int8(pollResult):
		default:
		}
	}
}

// FutureType represents the type of future return value
type FutureType int

const (
	FutureTypePointer FutureType = iota
	FutureTypeRustBuffer
	FutureTypeVoid
)

// pollFuture polls an async future until completion or context cancellation
func pollFuture(ctx context.Context, futureHandle uint64, futureType FutureType) (unsafe.Pointer, C.RustBuffer, error) {
	for {
		// Register callback
		callbackID, ch := registerCallback()
		defer unregisterCallback(callbackID)

		// Start polling
		callback := C.UniffiRustFutureContinuationCallback(C.goAsyncCallback)
		switch futureType {
		case FutureTypePointer:
			C.ffi_ant_ffi_rust_future_poll_pointer(C.uint64_t(futureHandle), callback, C.uint64_t(callbackID))
		case FutureTypeRustBuffer:
			C.ffi_ant_ffi_rust_future_poll_rust_buffer(C.uint64_t(futureHandle), callback, C.uint64_t(callbackID))
		case FutureTypeVoid:
			C.ffi_ant_ffi_rust_future_poll_void(C.uint64_t(futureHandle), callback, C.uint64_t(callbackID))
		}

		// Wait for callback or context cancellation
		select {
		case <-ctx.Done():
			// Cancel the future
			switch futureType {
			case FutureTypePointer:
				C.ffi_ant_ffi_rust_future_cancel_pointer(C.uint64_t(futureHandle))
				C.ffi_ant_ffi_rust_future_free_pointer(C.uint64_t(futureHandle))
			case FutureTypeRustBuffer:
				C.ffi_ant_ffi_rust_future_cancel_rust_buffer(C.uint64_t(futureHandle))
				C.ffi_ant_ffi_rust_future_free_rust_buffer(C.uint64_t(futureHandle))
			case FutureTypeVoid:
				C.ffi_ant_ffi_rust_future_cancel_void(C.uint64_t(futureHandle))
				C.ffi_ant_ffi_rust_future_free_void(C.uint64_t(futureHandle))
			}
			return nil, C.RustBuffer{}, ctx.Err()

		case pollResult := <-ch:
			// POLL_READY = 0, POLL_MAYBE_READY = 1
			if pollResult == 0 {
				// Future is ready, complete it
				var status C.RustCallStatus
				switch futureType {
				case FutureTypePointer:
					ptr := C.ffi_ant_ffi_rust_future_complete_pointer(C.uint64_t(futureHandle), &status)
					C.ffi_ant_ffi_rust_future_free_pointer(C.uint64_t(futureHandle))
					if err := checkStatus(&status, "async operation"); err != nil {
						return nil, C.RustBuffer{}, err
					}
					return ptr, C.RustBuffer{}, nil

				case FutureTypeRustBuffer:
					buf := C.ffi_ant_ffi_rust_future_complete_rust_buffer(C.uint64_t(futureHandle), &status)
					C.ffi_ant_ffi_rust_future_free_rust_buffer(C.uint64_t(futureHandle))
					if err := checkStatus(&status, "async operation"); err != nil {
						return nil, C.RustBuffer{}, err
					}
					return nil, buf, nil

				case FutureTypeVoid:
					C.ffi_ant_ffi_rust_future_complete_void(C.uint64_t(futureHandle), &status)
					C.ffi_ant_ffi_rust_future_free_void(C.uint64_t(futureHandle))
					if err := checkStatus(&status, "async operation"); err != nil {
						return nil, C.RustBuffer{}, err
					}
					return nil, C.RustBuffer{}, nil
				}
			}
			// Poll again if POLL_MAYBE_READY
			continue
		}
	}
}

// pollPointerFuture polls a pointer-returning future
func pollPointerFuture(ctx context.Context, futureHandle uint64) (unsafe.Pointer, error) {
	ptr, _, err := pollFuture(ctx, futureHandle, FutureTypePointer)
	return ptr, err
}

// pollRustBufferFuture polls a RustBuffer-returning future
func pollRustBufferFuture(ctx context.Context, futureHandle uint64) (C.RustBuffer, error) {
	_, buf, err := pollFuture(ctx, futureHandle, FutureTypeRustBuffer)
	return buf, err
}

// pollVoidFuture polls a void-returning future
func pollVoidFuture(ctx context.Context, futureHandle uint64) error {
	_, _, err := pollFuture(ctx, futureHandle, FutureTypeVoid)
	return err
}
