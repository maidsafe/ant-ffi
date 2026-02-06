package antffi

/*
#include <stdint.h>

typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

typedef struct {
    int32_t len;
    const uint8_t* data;
} ForeignBytes;

typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// RustBuffer represents a buffer allocated by Rust.
// It should be freed when no longer needed.
type RustBuffer struct {
	Capacity uint64
	Len      uint64
	Data     unsafe.Pointer
}

// toC converts a RustBuffer to its C representation.
func (rb RustBuffer) toC() C.RustBuffer {
	return C.RustBuffer{
		capacity: C.uint64_t(rb.Capacity),
		len:      C.uint64_t(rb.Len),
		data:     (*C.uint8_t)(rb.Data),
	}
}

// rustBufferFromC creates a RustBuffer from its C representation.
func rustBufferFromC(cb C.RustBuffer) RustBuffer {
	return RustBuffer{
		Capacity: uint64(cb.capacity),
		Len:      uint64(cb.len),
		Data:     unsafe.Pointer(cb.data),
	}
}

// ForeignBytes represents bytes owned by Go that will be passed to Rust.
type ForeignBytes struct {
	Len  int32
	Data unsafe.Pointer
}

// toC converts ForeignBytes to its C representation.
func (fb ForeignBytes) toC() C.ForeignBytes {
	return C.ForeignBytes{
		len:  C.int32_t(fb.Len),
		data: (*C.uint8_t)(fb.Data),
	}
}

// RustCallStatus represents the status of a Rust FFI call.
type RustCallStatus struct {
	Code     int8
	ErrorBuf RustBuffer
}

// newRustCallStatus creates a new zero-initialized RustCallStatus.
func newRustCallStatus() *C.RustCallStatus {
	return &C.RustCallStatus{}
}

// IsError returns true if the call resulted in an error.
func (s *RustCallStatus) IsError() bool {
	return s.Code != 0
}

// Handle is the base type for all native handle wrappers.
// It provides common functionality for freeing and cloning handles.
type Handle struct {
	ptr   unsafe.Pointer
	freed bool
	mu    sync.Mutex
}

// newHandle creates a new Handle with the given pointer and sets up a finalizer.
func newHandle(ptr unsafe.Pointer, freeFn func(unsafe.Pointer)) *Handle {
	h := &Handle{ptr: ptr}
	if freeFn != nil {
		runtime.SetFinalizer(h, func(h *Handle) {
			h.mu.Lock()
			defer h.mu.Unlock()
			if !h.freed && h.ptr != nil {
				freeFn(h.ptr)
				h.freed = true
			}
		})
	}
	return h
}

// Ptr returns the underlying pointer.
func (h *Handle) Ptr() unsafe.Pointer {
	return h.ptr
}

// IsFreed returns true if the handle has been freed.
func (h *Handle) IsFreed() bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	return h.freed
}

// markFreed marks the handle as freed (used after explicit Free() calls).
func (h *Handle) markFreed() {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.freed = true
}
